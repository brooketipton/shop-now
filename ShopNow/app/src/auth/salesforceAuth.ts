// OAuth 2.0 configuration for Salesforce authentication
export interface SalesforceConfig {
	clientId: string; // Connected App Consumer Key
	redirectUri: string; // Your app's redirect URI
	instanceUrl: string; // Salesforce org URL
}

export class SalesforceAuth {
	private config: SalesforceConfig;

	constructor(config: SalesforceConfig) {
		this.config = config;
	}

	// Generate OAuth authorization URL (implicit flow for browser apps)
	getAuthUrl(): string {
		const params = new URLSearchParams({
			response_type: "token", // Implicit flow for browser-based apps
			client_id: this.config.clientId,
			redirect_uri: this.config.redirectUri,
			scope: "api",
			state: this.generateState(),
		});

		return `${this.config.instanceUrl}/services/oauth2/authorize?${params}`;
	}

	// Parse access token from URL fragment (implicit flow)
	parseTokenFromUrl(): { accessToken: string; instanceUrl: string } | null {
		const hash = window.location.hash.substring(1);
		const params = new URLSearchParams(hash);

		const accessToken = params.get("access_token");
		const instanceUrl = params.get("instance_url");

		if (accessToken && instanceUrl) {
			// Store tokens with extended expiration (24 hours default)
			localStorage.setItem("sf_access_token", accessToken);
			localStorage.setItem("sf_instance_url", instanceUrl);

			// Set expiration to 2 hours (Salesforce default session timeout)
			const expirationTime = Date.now() + 2 * 60 * 60 * 1000;
			localStorage.setItem("sf_token_expires", expirationTime.toString());

			// Clean up URL
			window.history.replaceState({}, document.title, window.location.pathname);

			return { accessToken, instanceUrl };
		}

		return null;
	}

	// Get stored access token
	getAccessToken(): string | null {
		return localStorage.getItem("sf_access_token");
	}

	// Get stored instance URL
	getInstanceUrl(): string | null {
		return localStorage.getItem("sf_instance_url");
	}

	// Check if user is authenticated and token is still valid
	isAuthenticated(): boolean {
		const token = this.getAccessToken();
		const expires = localStorage.getItem("sf_token_expires");

		if (!token) return false;

		// Check if token is expired
		if (expires) {
			const expiresTime = parseInt(expires);
			const now = Date.now();

			if (now >= expiresTime) {
				// Token is expired, clear it
				this.logout();
				return false;
			}
		}

		return true;
	}

	// Logout and clear all tokens
	logout(): void {
		localStorage.removeItem("sf_access_token");
		localStorage.removeItem("sf_instance_url");
		localStorage.removeItem("sf_token_expires");
	}

	private generateState(): string {
		return Math.random().toString(36).substring(2, 15);
	}
}
