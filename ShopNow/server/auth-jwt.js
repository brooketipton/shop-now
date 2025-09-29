import fetch from "node-fetch";
import jwt from "jsonwebtoken";
import fs from "fs";

// JWT Bearer Token Flow (more commonly available)
export class SalesforceJWTAuth {
	constructor(config) {
		this.config = config;
		this.accessToken = null;
		this.tokenExpiration = null;
	}

	async getAccessToken() {
		// Check if current token is still valid
		if (
			this.accessToken &&
			this.tokenExpiration &&
			Date.now() < this.tokenExpiration
		) {
			return this.accessToken;
		}

		try {
			// Create JWT token
			const jwtToken = this.createJWT();

			// Exchange JWT for access token
			const tokenUrl = `${this.config.instanceUrl}/services/oauth2/token`;

			const body = new URLSearchParams({
				grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
				assertion: jwtToken,
			});

			const response = await fetch(tokenUrl, {
				method: "POST",
				headers: {
					"Content-Type": "application/x-www-form-urlencoded",
				},
				body: body.toString(),
			});

			if (!response.ok) {
				const errorText = await response.text();
				throw new Error(
					`JWT token exchange failed: ${response.statusText} - ${errorText}`
				);
			}

			const tokenData = await response.json();

			// Store token with expiration
			this.accessToken = tokenData.access_token;
			this.tokenExpiration = Date.now() + 2 * 60 * 60 * 1000; // 2 hours

			console.log("✅ New Salesforce access token obtained via JWT");
			return this.accessToken;
		} catch (error) {
			console.error("❌ Failed to get Salesforce access token via JWT:", error);
			throw error;
		}
	}

	createJWT() {
		const header = {
			alg: "RS256",
			typ: "JWT",
		};

		const now = Math.floor(Date.now() / 1000);
		const payload = {
			iss: this.config.clientId,
			sub: this.config.username,
			aud: this.config.instanceUrl,
			exp: now + 3 * 60, // 3 minutes from now
			iat: now,
		};

		// Read private key from file
		const privateKey = fs.readFileSync(this.config.privateKeyPath, "utf8");

		return jwt.sign(payload, privateKey, { algorithm: "RS256" });
	}
}
