// See https://svelte.dev/docs/kit/types#app.d.ts
declare global {
	namespace App {
		interface Locals {
			/** The authenticated account, or null when nobody is signed in. */
			account: { id: string; email: string; name?: string | null } | null;
			/** The CRM profile granting access, or null when the account is not provisioned. */
			profile: {
				id: string;
				email: string;
				first_name: string;
				last_name: string;
				active: boolean;
				role_name: string;
			} | null;
		}
	}
}

export {};
