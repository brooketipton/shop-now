import { http, HttpResponse } from "msw";
import { DuplicateMatch, ApiResponse } from "../../types";

// Mock data
const mockDuplicateMatches: DuplicateMatch[] = [
	{
		id: "a01XX000001234",
		customerA: {
			id: "a00XX000001111",
			firstName: "John",
			lastName: "Smith",
			email: "john.smith@example.com",
			phone: "555-1234",
		},
		customerB: {
			id: "a00XX000002222",
			firstName: "Jon",
			lastName: "Smith",
			email: "jon.smith@example.com",
			phone: "555-1234",
		},
		matchScore: 70,
		status: "Pending Review",
	},
	{
		id: "a01XX000005678",
		customerA: {
			id: "a00XX000003333",
			firstName: "Jane",
			lastName: "Doe",
			email: "jane.doe@example.com",
			phone: "555-5678",
		},
		customerB: {
			id: "a00XX000004444",
			firstName: "Jane",
			lastName: "D.",
			email: "j.doe@example.com",
			phone: "555-5678",
		},
		matchScore: 50,
		status: "Pending Review",
	},
];

export const handlers = [
	// GET /duplicates/pending
	http.get("http://localhost:3001/api/duplicates/pending", () => {
		return HttpResponse.json(mockDuplicateMatches);
	}),

	// GET /services/apexrest/duplicates/pending (direct Salesforce)
	http.get("*/services/apexrest/duplicates/pending", () => {
		return HttpResponse.json(mockDuplicateMatches);
	}),

	// POST /duplicates/{id}/resolve
	http.post(
		"http://localhost:3001/api/duplicates/:id/resolve",
		async ({ request, params }) => {
			const { id } = params;
			const body = (await request.json()) as { action: string };

			const response: ApiResponse = {
				success: true,
				message: `Duplicate match resolved successfully with action: ${body.action}`,
			};

			return HttpResponse.json(response);
		}
	),

	// POST /services/apexrest/duplicates/{id}/resolve (direct Salesforce)
	http.post(
		"*/services/apexrest/duplicates/:id/resolve",
		async ({ request, params }) => {
			const { id } = params;
			const body = (await request.json()) as { action: string };

			const response: ApiResponse = {
				success: true,
				message: `Duplicate match resolved successfully with action: ${body.action}`,
			};

			return HttpResponse.json(response);
		}
	),

	// Error scenarios
	http.get("http://localhost:3001/api/duplicates/error", () => {
		return HttpResponse.json(
			{ error: "Internal Server Error", message: "Something went wrong" },
			{ status: 500 }
		);
	}),

	http.post("http://localhost:3001/api/duplicates/error/resolve", () => {
		return HttpResponse.json(
			{ success: false, message: "Failed to resolve duplicate" },
			{ status: 400 }
		);
	}),
];
