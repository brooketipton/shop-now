#!/usr/bin/env node

const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");
const readline = require("readline");

// Colors for console output
const colors = {
	reset: "\x1b[0m",
	bright: "\x1b[1m",
	red: "\x1b[31m",
	green: "\x1b[32m",
	yellow: "\x1b[33m",
	blue: "\x1b[34m",
	cyan: "\x1b[36m",
};

function log(message, color = colors.reset) {
	console.log(`${color}${message}${colors.reset}`);
}

function createInterface() {
	return readline.createInterface({
		input: process.stdin,
		output: process.stdout,
	});
}

function question(rl, query) {
	return new Promise((resolve) => rl.question(query, resolve));
}

async function checkSalesforceCLI() {
	try {
		execSync("sf --version", { stdio: "pipe" });
		log("✓ Salesforce CLI found", colors.green);
		return true;
	} catch (error) {
		log("✗ Salesforce CLI not found. Please install it first:", colors.red);
		log("  npm install -g @salesforce/cli", colors.yellow);
		return false;
	}
}

async function getOrgInfo() {
	try {
		const result = execSync("sf org display --json", { encoding: "utf8" });
		const orgInfo = JSON.parse(result);
		if (orgInfo.status === 0) {
			return orgInfo.result;
		}
	} catch (error) {
		log("✗ No default org found. Authenticating now...", colors.yellow);
		return await authenticateWithSalesforce();
	}
}

async function authenticateWithSalesforce() {
	try {
		log("Opening Salesforce login in your browser...", colors.blue);

		// Use specific org URL if provided, otherwise use default
		const defaultOrgUrl =
			"https://customer-nosoftware-7615-dev-ed.scratch.my.salesforce.com";
		log(`Connecting to: ${defaultOrgUrl}`, colors.cyan);

		execSync(`sf org login web --instance-url ${defaultOrgUrl} --set-default`, {
			stdio: "inherit",
		});

		// After successful authentication, get org info
		const result = execSync("sf org display --json", { encoding: "utf8" });
		const orgInfo = JSON.parse(result);

		if (orgInfo.status === 0) {
			log("✓ Successfully authenticated with Salesforce", colors.green);
			log(`✓ Set as default org: ${orgInfo.result.username}`, colors.green);
			return orgInfo.result;
		} else {
			throw new Error("Authentication succeeded but could not get org info");
		}
	} catch (error) {
		log("✗ Authentication failed", colors.red);
		log(
			"Please try running 'sf org login web --instance-url https://customer-nosoftware-7615-dev-ed.scratch.my.salesforce.com --set-default' manually",
			colors.yellow
		);
		throw error;
	}
}

function createConnectedAppMetadata(email, instanceUrl) {
	const metadata = `<?xml version="1.0" encoding="UTF-8"?>
<ConnectedApp xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Duplicate Management App</label>
    <description>OAuth app for React-based duplicate management interface</description>
    <contactEmail>${email}</contactEmail>
    <oauthConfig>
        <callbackUrl>http://localhost:5173
http://localhost:3000</callbackUrl>
        <consumerKey>DuplicateManagementApp</consumerKey>
        <scopes>Api</scopes>
        <scopes>RefreshToken</scopes>
    </oauthConfig>
    <permissionSetName>Duplicate_Management_Access</permissionSetName>
</ConnectedApp>`;

	const metadataDir = path.join(
		__dirname,
		"..",
		"sf",
		"force-app",
		"main",
		"default",
		"connectedApps"
	);
	if (!fs.existsSync(metadataDir)) {
		fs.mkdirSync(metadataDir, { recursive: true });
	}

	const filePath = path.join(
		metadataDir,
		"Duplicate_Management_App.connectedApp-meta.xml"
	);
	fs.writeFileSync(filePath, metadata);
	return filePath;
}

async function deployConnectedApp(filePath) {
	try {
		log("Deploying Connected App...", colors.blue);

		// Change to sf directory for deployment
		const sfDir = path.join(__dirname, "..", "sf");
		process.chdir(sfDir);

		execSync(
			`sf project deploy start --source-dir ${path.relative(
				sfDir,
				path.dirname(filePath)
			)} --wait 10`,
			{ stdio: "inherit" }
		);
		log("✓ Connected App deployed successfully", colors.green);
		return true;
	} catch (error) {
		log("✗ Failed to deploy Connected App", colors.red);
		throw error;
	}
}

async function retrieveConsumerKey() {
	try {
		log("Retrieving Consumer Key...", colors.blue);

		// Wait a moment for the deployment to complete
		await new Promise((resolve) => setTimeout(resolve, 5000));

		// Retrieve the connected app metadata
		const retrieveDir = path.join(__dirname, "temp");
		if (!fs.existsSync(retrieveDir)) {
			fs.mkdirSync(retrieveDir, { recursive: true });
		}

		execSync(
			`sf project retrieve start --metadata ConnectedApp:Duplicate_Management_App --target-dir ${retrieveDir}`,
			{ stdio: "pipe" }
		);

		const metadataFile = path.join(
			retrieveDir,
			"force-app",
			"main",
			"default",
			"connectedApps",
			"Duplicate_Management_App.connectedApp-meta.xml"
		);

		if (fs.existsSync(metadataFile)) {
			const content = fs.readFileSync(metadataFile, "utf8");
			const consumerKeyMatch = content.match(
				/<consumerKey>(.*?)<\/consumerKey>/
			);

			if (consumerKeyMatch) {
				// Clean up temp directory
				fs.rmSync(retrieveDir, { recursive: true, force: true });
				return consumerKeyMatch[1];
			}
		}

		// Fallback: query via SOQL
		const result = execSync(
			`sf data query --query "SELECT ConsumerKey FROM ConnectedApplication WHERE Name = 'Duplicate Management App' LIMIT 1" --json`,
			{ encoding: "utf8" }
		);
		const queryResult = JSON.parse(result);

		if (queryResult.status === 0 && queryResult.result.records.length > 0) {
			return queryResult.result.records[0].ConsumerKey;
		}

		throw new Error("Could not retrieve Consumer Key");
	} catch (error) {
		log("✗ Failed to retrieve Consumer Key automatically", colors.red);
		log(
			"Please get it manually from Setup > App Manager > Duplicate Management App",
			colors.yellow
		);
		return null;
	}
}

function updateEnvFile(consumerKey, instanceUrl) {
	const envPath = path.join(__dirname, "..", "app", ".env");
	const envContent = `# Salesforce OAuth Configuration
VITE_SALESFORCE_CLIENT_ID=${consumerKey}
VITE_SALESFORCE_INSTANCE_URL=${instanceUrl}
VITE_SALESFORCE_REDIRECT_URI=http://localhost:5173

# API Base (will be dynamically set after OAuth)
VITE_API_BASE=${instanceUrl}/services/apexrest/duplicates
`;

	fs.writeFileSync(envPath, envContent);
	log("✓ .env file updated", colors.green);
}

async function addRemoteSite(instanceUrl) {
	try {
		log("Adding Remote Site Setting for CORS...", colors.blue);

		const remoteSiteMetadata = `<?xml version="1.0" encoding="UTF-8"?>
<RemoteSiteSetting xmlns="http://soap.sforce.com/2006/04/metadata">
    <disableProtocolSecurity>false</disableProtocolSecurity>
    <isActive>true</isActive>
    <url>http://localhost:5173</url>
</RemoteSiteSetting>`;

		const metadataDir = path.join(
			__dirname,
			"..",
			"sf",
			"force-app",
			"main",
			"default",
			"remoteSiteSettings"
		);
		if (!fs.existsSync(metadataDir)) {
			fs.mkdirSync(metadataDir, { recursive: true });
		}

		const filePath = path.join(
			metadataDir,
			"React_App_Local.remoteSiteSetting-meta.xml"
		);
		fs.writeFileSync(filePath, remoteSiteMetadata);

		// Change to sf directory for deployment
		const sfDir = path.join(__dirname, "..", "sf");
		const originalCwd = process.cwd();
		process.chdir(sfDir);

		execSync(
			`sf project deploy start --source-dir ${path.relative(
				sfDir,
				metadataDir
			)} --wait 10`,
			{
				stdio: "pipe",
			}
		);

		// Change back to original directory
		process.chdir(originalCwd);
		log("✓ Remote Site Setting added", colors.green);
	} catch (error) {
		log("⚠ Could not add Remote Site Setting automatically", colors.yellow);
		log("Please add manually: Setup > Remote Site Settings", colors.yellow);
		log("URL: http://localhost:5173", colors.yellow);
	}
}

async function main() {
	log("🚀 Salesforce OAuth Setup Script", colors.bright + colors.cyan);
	log("=====================================\n", colors.cyan);

	const rl = createInterface();

	try {
		// Check prerequisites
		if (!(await checkSalesforceCLI())) {
			process.exit(1);
		}

		// Get org info
		log("Checking Salesforce org...", colors.blue);
		const orgInfo = await getOrgInfo();
		log(`✓ Connected to org: ${orgInfo.username}`, colors.green);
		log(`✓ Instance URL: ${orgInfo.instanceUrl}`, colors.green);

		// Get user email
		const email = await question(
			rl,
			"\nEnter your email address for the Connected App contact: "
		);

		if (!email || !email.includes("@")) {
			log("✗ Invalid email address", colors.red);
			process.exit(1);
		}

		log(`\nUsing email: ${email}`, colors.green);
		log(`Instance URL: ${orgInfo.instanceUrl}`, colors.green);

		// Create Connected App metadata
		log("\nCreating Connected App metadata...", colors.blue);
		const metadataPath = createConnectedAppMetadata(email, orgInfo.instanceUrl);
		log(`✓ Metadata created: ${metadataPath}`, colors.green);

		// Deploy Connected App
		await deployConnectedApp(metadataPath);

		// Add Remote Site Setting
		await addRemoteSite(orgInfo.instanceUrl);

		// Retrieve Consumer Key
		const consumerKey = await retrieveConsumerKey();

		if (consumerKey) {
			log(
				`✓ Consumer Key retrieved: ${consumerKey.substring(0, 10)}...`,
				colors.green
			);

			// Update .env file
			updateEnvFile(consumerKey, orgInfo.instanceUrl);

			log("\n🎉 Setup completed successfully!", colors.bright + colors.green);
			log("\nNext steps:", colors.bright);
			log("1. cd app && npm install", colors.yellow);
			log("2. npm run dev", colors.yellow);
			log("3. Open http://localhost:5173", colors.yellow);
			log('4. Click "Login with Salesforce"', colors.yellow);
		} else {
			log("\n⚠ Setup partially completed", colors.yellow);
			log(
				"Please manually get the Consumer Key and update .env:",
				colors.yellow
			);
			log(
				"1. Setup > App Manager > Duplicate Management App > View",
				colors.yellow
			);
			log(
				"2. Copy Consumer Key to VITE_SALESFORCE_CLIENT_ID in app/.env",
				colors.yellow
			);
		}
	} catch (error) {
		log(`\n✗ Setup failed: ${error.message}`, colors.red);
		process.exit(1);
	} finally {
		rl.close();
	}
}

// Run the script
if (require.main === module) {
	main();
}

module.exports = { main };
