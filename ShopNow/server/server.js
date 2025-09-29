import express from "express";
import cors from "cors";
import fetch from "node-fetch";

const app = express();
const DEFAULT_PORT = 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Salesforce credentials (stored securely on server)
const SF_CONFIG = {
	instanceUrl:
		process.env.SF_INSTANCE_URL ||
		"https://customer-nosoftware-7615-dev-ed.scratch.my.salesforce.com",
	clientId: process.env.SF_CLIENT_ID,
	clientSecret: process.env.SF_CLIENT_SECRET,
	username: process.env.SF_USERNAME,
	password: process.env.SF_PASSWORD + process.env.SF_SECURITY_TOKEN, // password + security token
};

// Store access token and expiration
let accessToken = null;
let tokenExpiration = null;

// Get access token - using existing session from Salesforce CLI
async function getAccessToken() {
	// Use the session token from Salesforce CLI (from sf org display)
	const sessionToken = process.env.SF_SESSION_TOKEN;

	if (!sessionToken) {
		throw new Error("SF_SESSION_TOKEN environment variable not set");
	}

	console.log("✅ Using Salesforce CLI session token");
	return sessionToken;
}

// Proxy middleware for Salesforce API calls
async function proxySalesforceRequest(req, res, apiPath) {
	try {
		const token = await getAccessToken();

		const salesforceUrl = `${SF_CONFIG.instanceUrl}/services/apexrest/duplicates${apiPath}`;

		const options = {
			method: req.method,
			headers: {
				Authorization: `Bearer ${token}`,
				"Content-Type": "application/json",
			},
		};

		if (req.method !== "GET" && req.body) {
			options.body = JSON.stringify(req.body);
		}

		const response = await fetch(salesforceUrl, options);
		const data = await response.json();

		res.status(response.status).json(data);
	} catch (error) {
		console.error("Proxy error:", error);
		res.status(500).json({
			error: "Proxy request failed",
			message: error.message,
		});
	}
}

// API Routes
app.get("/api/duplicates/pending", (req, res) => {
	const queryParams = new URLSearchParams(req.query).toString();
	const apiPath = `/pending${queryParams ? `?${queryParams}` : ""}`;
	proxySalesforceRequest(req, res, apiPath);
});

app.post("/api/duplicates/:id/resolve", (req, res) => {
	const apiPath = `/${req.params.id}/resolve`;
	proxySalesforceRequest(req, res, apiPath);
});

// Health check
app.get("/health", (req, res) => {
	res.json({ status: "OK", timestamp: new Date().toISOString() });
});

// Function to find available port
function findAvailablePort(startPort, maxAttempts = 10) {
	return new Promise((resolve, reject) => {
		let currentPort = startPort;
		let attempts = 0;

		function tryPort() {
			if (attempts >= maxAttempts) {
				reject(
					new Error(
						`Could not find available port after ${maxAttempts} attempts`
					)
				);
				return;
			}

			const server = app
				.listen(currentPort)
				.on("listening", () => {
					resolve({ server, port: currentPort });
				})
				.on("error", (err) => {
					if (err.code === "EADDRINUSE") {
						console.log(
							`⚠️  Port ${currentPort} is in use, trying ${currentPort + 1}...`
						);
						currentPort++;
						attempts++;
						tryPort();
					} else {
						reject(err);
					}
				});
		}

		tryPort();
	});
}

// Start server with port fallback
findAvailablePort(DEFAULT_PORT)
	.then(({ server, port }) => {
		console.log(
			`🚀 Salesforce proxy server running on http://localhost:${port}`
		);
		console.log(`📋 Health check: http://localhost:${port}/health`);

		if (port !== DEFAULT_PORT) {
			console.log(
				`📝 Note: Using port ${port} instead of default ${DEFAULT_PORT}`
			);
		}

		// Validate configuration
		if (
			!SF_CONFIG.clientId ||
			!SF_CONFIG.clientSecret ||
			!SF_CONFIG.username ||
			!SF_CONFIG.password
		) {
			console.warn(
				"⚠️  Missing Salesforce credentials in environment variables"
			);
			console.log(
				"Required: SF_CLIENT_ID, SF_CLIENT_SECRET, SF_USERNAME, SF_PASSWORD, SF_SECURITY_TOKEN"
			);
		}

		// Graceful shutdown
		process.on("SIGTERM", () => {
			console.log("🛑 Received SIGTERM, shutting down gracefully...");
			server.close(() => {
				console.log("✅ Server closed");
				process.exit(0);
			});
		});

		process.on("SIGINT", () => {
			console.log("\n🛑 Received SIGINT, shutting down gracefully...");
			server.close(() => {
				console.log("✅ Server closed");
				process.exit(0);
			});
		});
	})
	.catch((error) => {
		console.error("❌ Failed to start server:", error.message);
		process.exit(1);
	});
