import axios from "axios";
import { DuplicateMatch, ApiResponse } from "./types";

const getBaseURL = () => {
	// Try to get from localStorage first, fallback to env variable
	return (
		localStorage.getItem("salesforce_base_url") || import.meta.env.VITE_API_BASE
	);
};

const api = axios.create({
	headers: {
		"Content-Type": "application/json",
	},
});

// Set base URL dynamically
api.defaults.baseURL = getBaseURL();

// Add request interceptor for authentication
api.interceptors.request.use((config) => {
	// Try OAuth token first, fallback to session ID
	const accessToken = localStorage.getItem("sf_access_token");
	const sessionId = localStorage.getItem("salesforce_session_id");

	if (accessToken) {
		config.headers.Authorization = `Bearer ${accessToken}`;
	} else if (sessionId) {
		config.headers.Authorization = `Bearer ${sessionId}`;
	}

	// Update base URL from stored instance URL if available
	const instanceUrl = localStorage.getItem("sf_instance_url");
	if (instanceUrl) {
		config.baseURL = `${instanceUrl}/services/apexrest`;
	}

	return config;
});

// Add response interceptor for error handling
api.interceptors.response.use(
	(response) => response,
	(error) => {
		if (error.response?.status === 401) {
			// Handle authentication errors - try to refresh token first
			console.error("Authentication failed - token may be expired");

			// Clear tokens and redirect to login
			localStorage.removeItem("salesforce_session_id");
			localStorage.removeItem("sf_access_token");
			localStorage.removeItem("sf_refresh_token");
			localStorage.removeItem("sf_instance_url");
			localStorage.removeItem("sf_token_expires");

			// Reload page to trigger login flow
			window.location.reload();
		}
		return Promise.reject(error);
	}
);

export const duplicateApi = {
	/**
	 * GET /duplicates/pending
	 * Returns all duplicate matches with status 'Pending Review'
	 */
	getPending: async (): Promise<DuplicateMatch[]> => {
		const response = await api.get("/duplicates/pending");
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
		const response = await api.post(`/duplicates/${matchId}/resolve`, {
			action,
		});
		return response.data;
	},
};
