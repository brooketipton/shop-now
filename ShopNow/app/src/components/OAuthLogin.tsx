import { useEffect, useState } from "react";
import { SalesforceAuth, SalesforceConfig } from "../auth/salesforceAuth";

const defaultConfig: SalesforceConfig = {
	clientId: import.meta.env.VITE_SALESFORCE_CLIENT_ID || "",
	redirectUri:
		import.meta.env.VITE_SALESFORCE_REDIRECT_URI || window.location.origin,
	instanceUrl: import.meta.env.VITE_SALESFORCE_INSTANCE_URL || "",
};

export default function OAuthLogin() {
	const [auth] = useState(() => new SalesforceAuth(defaultConfig));
	const [isAuthenticated, setIsAuthenticated] = useState(false);
	const [loading, setLoading] = useState(true);

	useEffect(() => {
		// Check if we're returning from OAuth
		const tokens = auth.parseTokenFromUrl();
		if (tokens) {
			setIsAuthenticated(true);
			setLoading(false);
			return;
		}

		// Check if already authenticated
		const isAuth = auth.isAuthenticated();
		setIsAuthenticated(isAuth);
		setLoading(false);
	}, [auth]);

	const handleLogin = () => {
		window.location.href = auth.getAuthUrl();
	};

	const handleLogout = () => {
		auth.logout();
		setIsAuthenticated(false);
	};

	if (loading) {
		return <div>Loading...</div>;
	}

	if (!isAuthenticated) {
		return (
			<div
				style={{
					padding: "16px",
					margin: "16px 0",
					border: "1px solid #ddd",
					borderRadius: "8px",
					backgroundColor: "#f9f9f9",
					textAlign: "center",
				}}>
				<h3>Salesforce Authentication Required</h3>
				<p>Please login to Salesforce to access duplicate management.</p>
				<button
					onClick={handleLogin}
					style={{
						padding: "12px 24px",
						backgroundColor: "#0070f3",
						color: "white",
						border: "none",
						borderRadius: "4px",
						cursor: "pointer",
						fontSize: "16px",
					}}>
					Login with Salesforce
				</button>

				<div style={{ marginTop: "16px", fontSize: "14px", color: "#666" }}>
					<p>
						<strong>Setup Required:</strong>
					</p>
					<ol
						style={{ textAlign: "left", maxWidth: "500px", margin: "0 auto" }}>
						<li>Create a Connected App in Salesforce Setup</li>
						<li>Add environment variables to .env file</li>
						<li>Configure OAuth settings</li>
					</ol>
				</div>
			</div>
		);
	}

	return (
		<div
			style={{
				padding: "16px",
				margin: "16px 0",
				border: "1px solid #28a745",
				borderRadius: "8px",
				backgroundColor: "#d4edda",
				display: "flex",
				justifyContent: "space-between",
				alignItems: "center",
			}}>
			<div>
				<strong>✓ Authenticated with Salesforce</strong>
				<div style={{ fontSize: "14px", color: "#666" }}>
					Instance: {auth.getInstanceUrl()}
				</div>
			</div>
			<button
				onClick={handleLogout}
				style={{
					padding: "8px 16px",
					backgroundColor: "#dc3545",
					color: "white",
					border: "none",
					borderRadius: "4px",
					cursor: "pointer",
				}}>
				Logout
			</button>
		</div>
	);
}
