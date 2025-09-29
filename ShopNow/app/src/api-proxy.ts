import axios from "axios";
import { DuplicateMatch, ApiResponse } from "./types";

// Use local proxy server instead of direct Salesforce calls
const api = axios.create({
	baseURL: "http://localhost:3001/api/duplicates",
	headers: {
		"Content-Type": "application/json",
	},
});

// No authentication needed - proxy server handles it
export const duplicateApi = {
	/**
	 * GET /duplicates/pending
	 * Returns all duplicate matches with status 'Pending Review'
	 */
	getPending: async (): Promise<DuplicateMatch[]> => {
		const response = await api.get("/pending");
		return response.data;
	},

	/**
	 * POST /duplicates/{id}/resolve
	 * Resolves a duplicate match by merging or ignoring
	 */
	resolve: async (
		matchId: string,
		action: "merge" | "ignore"
	): Promise<ApiResponse> => {
		const response = await api.post(`/${matchId}/resolve`, { action });
		return response.data;
	},
};
