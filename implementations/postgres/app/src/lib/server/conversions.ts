import { withUser } from './db';
import { createInTx, tableName } from './PostgresMapper';

/**
 * Conversion flows (stories 3, 5-7), ported from the reference implementation's dialogs but
 * executed server-side in one transaction each. The reference performs up to six sequential
 * client-side creates; a failure halfway leaves, say, an account without its contact. Here
 * a conversion either happens or it does not.
 */

type Source = Record<string, unknown>;

/** UX32 document conversion table, verbatim from the reference implementation. */
export const DOCUMENT_CONVERSIONS: Record<
	string,
	{ targetType: string; label: string; fieldMap: Record<string, string>; setFields: (src: Source) => Record<string, unknown>; copyLineItems: boolean }[]
> = {
	Opportunity: [
		{
			targetType: 'Quotation',
			label: 'Create Quotation',
			fieldMap: { account_id: 'account_id', currency: 'currency', owner_id: 'owner_id' },
			setFields: (src) => ({ opportunity_id: src.id, status: 'Draft' }),
			copyLineItems: true
		},
		{
			targetType: 'SalesOrder',
			label: 'Create Sales Order',
			fieldMap: { account_id: 'account_id', currency: 'currency', owner_id: 'owner_id' },
			setFields: (src) => ({ opportunity_id: src.id, status: 'Draft', order_date: today() }),
			copyLineItems: true
		}
	],
	Quotation: [
		{
			targetType: 'SalesOrder',
			label: 'Create Sales Order',
			fieldMap: { account_id: 'account_id', contact_id: 'contact_id', opportunity_id: 'opportunity_id', currency: 'currency', owner_id: 'owner_id' },
			setFields: (src) => ({ quotation_id: src.id, status: 'Draft', order_date: today() }),
			copyLineItems: true
		}
	],
	SalesOrder: [
		{
			targetType: 'Invoice',
			label: 'Create Invoice',
			fieldMap: { account_id: 'account_id', contact_id: 'contact_id', currency: 'currency', owner_id: 'owner_id' },
			setFields: (src) => ({ sales_order_id: src.id, status: 'Draft', invoice_date: today(), due_date: inDays(30) }),
			copyLineItems: true
		}
	]
};

const today = () => new Date().toISOString().slice(0, 10);
const inDays = (days: number) => new Date(Date.now() + days * 86_400_000).toISOString().slice(0, 10);

/** Fields carried over when a line item is copied to the new document. */
const LINE_ITEM_COPY = [
	'item_number', 'product_id', 'quantity', 'unit_price', 'discount_percent',
	'total_price', 'unit_of_measure', 'comment', 'alternative_to'
];

export async function convertDocument(
	profileId: string,
	sourceType: string,
	sourceId: string,
	targetType: string
): Promise<{ id: string; objectType: string; lineItems: number }> {
	const conversion = DOCUMENT_CONVERSIONS[sourceType]?.find((c) => c.targetType === targetType);
	if (!conversion) throw new Error(`No conversion from ${sourceType} to ${targetType}`);

	return withUser(profileId, async (client) => {
		const source = (
			await client.query(`select * from ${tableName(sourceType)} where id = $1`, [sourceId])
		).rows[0] as Source | undefined;
		if (!source) throw new Error('Source record not found');

		const data: Record<string, unknown> = {};
		for (const [targetField, sourceField] of Object.entries(conversion.fieldMap)) {
			const value = source[sourceField];
			if (value !== undefined && value !== null && value !== '') data[targetField] = value;
		}
		Object.assign(data, conversion.setFields(source));

		const created = await createInTx(client, profileId, targetType, data);

		let copied = 0;
		if (conversion.copyLineItems) {
			const items = (
				await client.query(
					`select * from line_item where parent_type = $1 and parent_id = $2 order by item_number`,
					[sourceType, sourceId]
				)
			).rows as Source[];
			for (const item of items) {
				const copy: Record<string, unknown> = { parent_type: targetType, parent_id: created.id };
				for (const field of LINE_ITEM_COPY) {
					if (item[field] !== null && item[field] !== undefined) copy[field] = item[field];
				}
				await createInTx(client, profileId, 'LineItem', copy);
				copied += 1;
			}
		}
		return { id: String(created.id), objectType: targetType, lineItems: copied };
	});
}

export async function convertLead(
	profileId: string,
	leadId: string,
	options: { accountName?: string; createOpportunity?: boolean; opportunityName?: string }
): Promise<{ accountId: string; contactId: string; opportunityId: string | null }> {
	return withUser(profileId, async (client) => {
		const lead = (await client.query('select * from lead where id = $1', [leadId])).rows[0] as Source | undefined;
		if (!lead) throw new Error('Lead not found');
		if (lead.status === 'Converted') throw new Error('Lead is already converted');

		const fullName = [lead.first_name, lead.last_name].filter(Boolean).join(' ');
		const account = await createInTx(client, profileId, 'Account', {
			name1: options.accountName || lead.company || fullName,
			phone: lead.phone ?? undefined,
			website: lead.website ?? undefined,
			owner_id: lead.owner_id,
			status: 'Active'
		});
		const contact = await createInTx(client, profileId, 'Contact', {
			first_name: lead.first_name,
			last_name: lead.last_name,
			email: lead.email ?? undefined,
			phone: lead.phone ?? undefined,
			mobile: lead.mobile ?? undefined,
			position: lead.position ?? undefined,
			account_id: account.id,
			owner_id: lead.owner_id,
			status: 'Active'
		});
		await createInTx(client, profileId, 'ContactAccount', {
			contact_id: contact.id,
			account_id: account.id,
			role: 'Primary'
		});

		let opportunityId: string | null = null;
		if (options.createOpportunity) {
			// First stage by sort order; an empty instance gets a default, as in the reference.
			let stage = (await client.query('select id from pipeline_stage order by sort_order limit 1')).rows[0];
			if (!stage) {
				stage = await createInTx(client, profileId, 'PipelineStage', {
					name: 'Qualification', sort_order: 1, probability: 10
				});
			}
			const opportunity = await createInTx(client, profileId, 'Opportunity', {
				name: options.opportunityName || fullName,
				account_id: account.id,
				stage_id: stage.id,
				owner_id: lead.owner_id
			});
			await createInTx(client, profileId, 'OpportunityContact', {
				opportunity_id: opportunity.id,
				contact_id: contact.id,
				role: 'Decision Maker'
			});
			opportunityId = String(opportunity.id);
		}

		await client.query(
			`update lead set status = 'Converted', converted_at = now(),
			        converted_account_id = $2, converted_contact_id = $3, converted_opportunity_id = $4,
			        updated_at = now(), updated_by = $5
			  where id = $1`,
			[leadId, account.id, contact.id, opportunityId, profileId]
		);
		return { accountId: String(account.id), contactId: String(contact.id), opportunityId };
	});
}
