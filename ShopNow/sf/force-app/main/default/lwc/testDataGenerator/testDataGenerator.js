import { LightningElement, track } from "lwc";
import generateTestData from "@salesforce/apex/TestDataController.generateTestData";
import clearAllData from "@salesforce/apex/TestDataController.clearAllData";
import runDuplicateScan from "@salesforce/apex/TestDataController.runDuplicateScan";
import getDataStatistics from "@salesforce/apex/TestDataController.getDataStatistics";

export default class TestDataGenerator extends LightningElement {
	@track isLoading = false;
	@track showMessage = false;
	@track messageTitle = "";
	@track messageText = "";
	@track messageType = "";
	@track errors = [];
	@track statistics = {
		totalCustomers: 0,
		pendingMatches: 0,
		mergedMatches: 0,
		ignoredMatches: 0,
		mergedCustomers: 0
	};

	get messageVariant() {
		const baseClass = "slds-notify slds-notify_alert slds-m-bottom_medium";
		return this.messageType === "success" ? `${baseClass} slds-alert_success` : `${baseClass} slds-alert_error`;
	}

	get hasErrors() {
		return this.errors && this.errors.length > 0;
	}

	connectedCallback() {
		this.loadStatistics();
	}

	async loadStatistics() {
		try {
			const result = await getDataStatistics();
			console.log("result", JSON.stringify(result));
			this.statistics = { ...result };
		} catch (error) {
			console.error("Error loading statistics:", error);
			this.showErrorMessage("Failed to Load Statistics", "Unable to retrieve current data statistics.");
		}
	}

	refreshStatistics() {
		this.loadStatistics();
	}

	/**
	 * Generates comprehensive test customer data
	 */
	async generateTestData() {
		this.isLoading = true;
		this.hideMessage();

		try {
			const result = await generateTestData();

			if (result.success) {
				this.showSuccessMessage("Test Data Generated Successfully", result.message);
				// Refresh statistics after successful generation
				await this.loadStatistics();
			} else {
				this.showErrorMessage("Test Data Generation Failed", result.message, result.errors);
			}
		} catch (error) {
			console.error("Error generating test data:", error);
			this.showErrorMessage(
				"Unexpected Error",
				"An unexpected error occurred while generating test data. Please try again."
			);
		} finally {
			this.isLoading = false;
		}
	}

	/**
	 * Clears all customer and duplicate match data
	 */
	async clearAllData() {
		const confirmed = confirm(
			"Are you sure you want to delete ALL customer and duplicate match data? This action cannot be undone."
		);

		if (!confirmed) {
			return;
		}

		this.isLoading = true;
		this.hideMessage();

		try {
			const result = await clearAllData();

			if (result.success) {
				this.showSuccessMessage("Data Cleared Successfully", result.message);
				// Refresh statistics after successful clearing
				await this.loadStatistics();
			} else {
				this.showErrorMessage("Data Clearing Failed", result.message, result.errors);
			}
		} catch (error) {
			console.error("Error clearing data:", error);
			this.showErrorMessage(
				"Unexpected Error",
				"An unexpected error occurred while clearing data. Please try again."
			);
		} finally {
			this.isLoading = false;
		}
	}

	/**
	 * Runs the duplicate scan batch job
	 */
	async runDuplicateScan() {
		this.isLoading = true;
		this.hideMessage();

		try {
			const result = await runDuplicateScan();

			if (result.success) {
				this.showSuccessMessage(
					"Duplicate Scan Started",
					result.message + " Check the Apex Jobs page for progress updates."
				);

				// Automatically refresh statistics after a delay to show scan results
				setTimeout(() => {
					this.loadStatistics();
				}, 5000); // Refresh after 5 seconds
			} else {
				this.showErrorMessage("Duplicate Scan Failed", result.message, result.errors);
			}
		} catch (error) {
			console.error("Error running duplicate scan:", error);
			this.showErrorMessage(
				"Unexpected Error",
				"An unexpected error occurred while starting the duplicate scan. Please try again."
			);
		} finally {
			this.isLoading = false;
		}
	}

	showSuccessMessage(title, message) {
		this.messageTitle = title;
		this.messageText = message;
		this.messageType = "success";
		this.errors = [];
		this.showMessage = true;
	}

	showErrorMessage(title, message, errors = []) {
		this.messageTitle = title;
		this.messageText = message;
		this.messageType = "error";
		this.errors = errors || [];
		this.showMessage = true;
	}

	hideMessage() {
		this.showMessage = false;
		this.messageTitle = "";
		this.messageText = "";
		this.messageType = "";
		this.errors = [];
	}

	dismissMessage() {
		this.hideMessage();
	}
}
