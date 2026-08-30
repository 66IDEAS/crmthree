import { withOwner } from './db';
import { decryptSecret } from './crypto';

/**
 * AI provider proxy (R5, P11). Same pluggable provider set as the reference implementation,
 * request shapes ported from its Cloud Function. The provider key is ciphertext in the
 * database; it is decrypted here, in the server process, and never reaches the browser.
 *
 * The active config is read on the owner connection: the api_key column is deliberately
 * unreadable by the application role, and this module is the one place that needs it.
 */
type Message = { role: 'system' | 'user' | 'assistant'; content: string };
type ProviderConfig = { provider: string; model: string; api_key: string; endpoint_url: string | null };
type AIResult = { content: string; model: string; tokens_used: number };

const OPENAI_COMPAT: Record<string, string> = {
	OpenAI: 'https://api.openai.com/v1/chat/completions',
	Moonshot: 'https://api.moonshot.cn/v1/chat/completions'
};

type ProviderRequest = {
	url: string;
	headers: Record<string, string>;
	body: unknown;
	parse: (data: any) => AIResult;
};

function buildRequest(config: ProviderConfig, messages: Message[]): ProviderRequest {
	if (config.provider === 'Google') {
		const base = config.endpoint_url || 'https://generativelanguage.googleapis.com/v1beta';
		const system = messages.find((m) => m.role === 'system');
		return {
			url: `${base}/models/${config.model || 'gemini-2.0-flash'}:generateContent?key=${config.api_key}`,
			headers: { 'content-type': 'application/json' },
			body: {
				contents: messages
					.filter((m) => m.role !== 'system')
					.map((m) => ({ role: m.role === 'assistant' ? 'model' : 'user', parts: [{ text: m.content }] })),
				...(system && { systemInstruction: { parts: [{ text: system.content }] } })
			},
			parse: (data: any): AIResult => ({
				content: data.candidates?.[0]?.content?.parts?.[0]?.text ?? '',
				model: data.modelVersion ?? '',
				tokens_used: data.usageMetadata?.totalTokenCount ?? 0
			})
		};
	}
	if (config.provider === 'Anthropic') {
		const system = messages.find((m) => m.role === 'system');
		return {
			url: config.endpoint_url || 'https://api.anthropic.com/v1/messages',
			headers: {
				'content-type': 'application/json',
				'x-api-key': config.api_key,
				'anthropic-version': '2023-06-01'
			},
			body: {
				model: config.model,
				max_tokens: 1024,
				messages: messages.filter((m) => m.role !== 'system'),
				...(system && { system: system.content })
			},
			parse: (data: any): AIResult => ({
				content: data.content?.[0]?.text ?? '',
				model: data.model ?? '',
				tokens_used: (data.usage?.input_tokens ?? 0) + (data.usage?.output_tokens ?? 0)
			})
		};
	}
	// OpenAI and OpenAI-compatible providers.
	let url = config.endpoint_url || OPENAI_COMPAT[config.provider] || OPENAI_COMPAT.OpenAI;
	if (!url.endsWith('/chat/completions')) url = url.replace(/\/+$/, '') + '/chat/completions';
	return {
		url,
		headers: { 'content-type': 'application/json', authorization: `Bearer ${config.api_key}` },
		body: { model: config.model, messages },
		parse: (data: any): AIResult => ({
			content: data.choices?.[0]?.message?.content ?? '',
			model: data.model ?? '',
			tokens_used: data.usage?.total_tokens ?? 0
		})
	};
}

export async function activeConfig(): Promise<ProviderConfig | null> {
	return withOwner(async (client) => {
		const result = await client.query(
			`select provider, model, api_key, endpoint_url from ai_provider_config
			  where is_active limit 1`
		);
		return result.rows[0] ?? null;
	});
}

export async function callProvider(messages: Message[]): Promise<AIResult> {
	const config = await activeConfig();
	if (!config) throw new Error('No active AI provider is configured');
	const request = buildRequest({ ...config, api_key: decryptSecret(config.api_key) }, messages);
	const response = await fetch(request.url, {
		method: 'POST',
		headers: request.headers,
		body: JSON.stringify(request.body)
	});
	if (!response.ok) {
		const detail = await response.text().catch(() => '');
		throw new Error(`Provider returned ${response.status}: ${detail.slice(0, 300)}`);
	}
	return request.parse(await response.json());
}
