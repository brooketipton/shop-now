import express from "express";
import cors from "cors";
import fetch from "node-fetch";
import dotenv from "dotenv";

// load env variables
dotenv.config();

const app = express();
const DEFAULT_PORT = 3001;

app.use(cors());
app.use(express.json());

const SF_CONFIG = {
	instanceUrl:
		process.env.SF_INSTANCE_URL ||
		"https://customer-nosoftware-7615-dev-ed.scratch.my.salesforce.com",
	clientId: process.env.SF_CLIENT_ID,
	clientSecret: process.env.SF_CLIENT_SECRET,
	username: process.env.SF_USERNAME,
	password: process.env.SF_PASSWORD,
	securityToken: process.env.SF_SECURITY_TOKEN,
};

let accessToken = null;
let tokenExpiration = null;

// mock data for when salesforce is not authed
const MOCK_DUPLICATES = [
	{
		id: "mock1",
		matchScore: 0.92,
		customerA: {
			id: "cust1",
			firstName: "John",
			lastName: "Smith",
			email: "john.smith@email.com",
			phone: "(555) 123-4567",
		},
		customerB: {
			id: "cust2",
			firstName: "Jon",
			lastName: "Smith",
			email: "jon.smith@gmail.com",
			phone: "(555) 123-4567",
		},
	},
	{
		id: "mock2",
		matchScore: 0.87,
		customerA: {
			id: "cust3",
			firstName: "Sarah",
			lastName: "Johnson",
			email: "sarah.johnson@company.com",
			phone: "(555) 987-6543",
		},
		customerB: {
			id: "cust4",
			firstName: "Sara",
			lastName: "Johnson",
			email: "sara.johnson@company.org",
			phone: "(555) 987-6543",
		},
	},
	{
		id: "mock3",
		matchScore: 0.75,
		customerA: {
			id: "cust5",
			firstName: "Michael",
			lastName: "Brown",
			email: "m.brown@email.com",
			phone: "(555) 555-0123",
		},
		customerB: {
			id: "cust6",
			firstName: "Mike",
			lastName: "Brown",
			email: "mike.brown@email.com",
			phone: "(555) 555-0123",
		},
	},
];

// tries OAuth first, falls back to CLI token
async function getAccessToken() {
	if (accessToken && tokenExpiration && Date.now() < tokenExpiration) {
		return accessToken;
	}

	if (
		SF_CONFIG.clientId &&
		SF_CONFIG.clientSecret &&
		SF_CONFIG.username &&
		SF_CONFIG.password
	) {
		try {
			const tokenUrl = `${SF_CONFIG.instanceUrl}/services/oauth2/token`;

			const params = new URLSearchParams({
				grant_type: "password",
				client_id: SF_CONFIG.clientId,
				client_secret: SF_CONFIG.clientSecret,
				username: SF_CONFIG.username,
				password: SF_CONFIG.password + (SF_CONFIG.securityToken || ""),
			});

			const response = await fetch(tokenUrl, {
				method: "POST",
				headers: {
					"Content-Type": "application/x-www-form-urlencoded",
				},
				body: params.toString(),
			});

			if (response.ok) {
				const tokenData = await response.json();
				accessToken = tokenData.access_token;
				tokenExpiration = Date.now() + 2 * 60 * 60 * 1000; // 2 hours
				console.log("Connected App OAuth successful");
				return accessToken;
			} else {
				console.log("OAuth failed, trying CLI token fallback");
			}
		} catch (error) {
			console.log("OAuth error, trying CLI token fallback");
		}
	}

	try {
		const { exec } = await import("child_process");
		const { promisify } = await import("util");
		const execAsync = promisify(exec);

		const { stdout } = await execAsync("sf org display user --json", {
			cwd: process.cwd(),
		});
		const orgData = JSON.parse(stdout);

		if (orgData.result && orgData.result.accessToken) {
			accessToken = orgData.result.accessToken;
			tokenExpiration = Date.now() + 2 * 60 * 60 * 1000; // 2 hours
			console.log("Using fresh Salesforce CLI token");
			return accessToken;
		}
	} catch (error) {
		console.log("Could not retrieve CLI token: ", error.message);
	}

	console.log("No auth was successful, falling back to mock data mode");
	return "MOCK_TOKEN";
}

async function proxySalesforceRequest(req, res, apiPath) {
	try {
		const token = await getAccessToken();

		if (token === "MOCK_TOKEN") {
			console.log("Returning mock data for API path:", apiPath);

			if (apiPath.startsWith("/pending") && req.method === "GET") {
				return res.json(MOCK_DUPLICATES);
			} else if (req.method === "POST") {
				return res.json({
					success: true,
					message: "Mock operation completed successfully",
				});
			}

			return res.json([]);
		}

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

app.get("/api/duplicates/pending", (req, res) => {
	const queryParams = new URLSearchParams(req.query).toString();
	const apiPath = `/pending${queryParams ? `?${queryParams}` : ""}`;
	proxySalesforceRequest(req, res, apiPath);
});

app.post("/api/duplicates/:id/resolve", (req, res) => {
	const apiPath = `/${req.params.id}/resolve`;
	proxySalesforceRequest(req, res, apiPath);
});

app.get("/health", (req, res) => {
	res.json({ status: "OK", timestamp: new Date().toISOString() });
});

const PORT = process.env.PORT || DEFAULT_PORT;

app.listen(PORT, () => {
	console.log(`Salesforce proxy server running on http://localhost:${PORT}`);
	console.log(`Health check: http://localhost:${PORT}/health`);
});
