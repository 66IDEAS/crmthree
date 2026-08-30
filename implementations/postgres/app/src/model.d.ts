/**
 * The data model is read from specs/data-model.json through a Vite alias rather than being
 * forked into the implementation. See vite.config.ts and src/lib/model/ModelRegistry.ts.
 */
declare module '$model' {
	export interface FieldDefinition {
		name: string;
		type: string;
		length?: number;
		precision?: number;
		scale?: number;
		required?: boolean;
		unique?: boolean;
		primary_key?: boolean;
		auto_generated?: boolean;
		values?: string[];
		target?: string;
		default?: unknown;
		description?: string;
	}
	export interface Relationship {
		name: string;
		type: string;
		target: string;
		through?: string;
		foreign_key?: string;
	}
	export interface ObjectDefinition {
		description?: string;
		fields: FieldDefinition[];
		relationships?: Relationship[];
	}
	const model: {
		version: string;
		field_types: Record<string, string>;
		common_fields: FieldDefinition[];
		objects: Record<string, ObjectDefinition>;
	};
	export default model;
}
