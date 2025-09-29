import { describe, it, expect } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import App from "../../App";

// Test utilities
const createTestQueryClient = () =>
	new QueryClient({
		defaultOptions: {
			queries: {
				retry: false,
			},
			mutations: {
				retry: false,
			},
		},
	});

const renderApp = () => {
	const queryClient = createTestQueryClient();
	return render(
		<QueryClientProvider client={queryClient}>
			<App />
		</QueryClientProvider>
	);
};

describe("App", () => {
	describe("header", () => {
		it("should render the main title", () => {
			renderApp();

			expect(
				screen.getByText("ShopNow - Duplicate Customer Management")
			).toBeInTheDocument();
		});

		it("should render the subtitle", () => {
			renderApp();

			expect(
				screen.getByText(
					"Review and resolve potential duplicate customer records"
				)
			).toBeInTheDocument();
		});

		it("should show connection status", () => {
			renderApp();

			expect(screen.getByText("Connected to Salesforce")).toBeInTheDocument();
			expect(screen.getByText("✅")).toBeInTheDocument();
		});
	});

	describe("layout", () => {
		it("should have proper semantic structure", () => {
			renderApp();

			// Check for semantic HTML elements
			expect(screen.getByRole("banner")).toBeInTheDocument(); // header
			expect(screen.getByRole("main")).toBeInTheDocument(); // main
		});

		it("should apply consistent styling", () => {
			renderApp();

			const header = screen.getByRole("banner");
			expect(header).toBeInTheDocument();

			const main = screen.getByRole("main");
			expect(main).toBeInTheDocument();
		});
	});

	describe("content", () => {
		it("should render the DuplicateTable component", async () => {
			renderApp();

			// Wait for the table to load
			await waitFor(() => {
				expect(
					screen.getByText("Loading duplicate matches...")
				).toBeInTheDocument();
			});

			// Eventually should show the table content
			await waitFor(
				() => {
					expect(
						screen.getByText("Pending Duplicate Reviews")
					).toBeInTheDocument();
				},
				{ timeout: 3000 }
			);
		});

		it("should show duplicate data when loaded", async () => {
			renderApp();

			// Wait for data to load
			await waitFor(
				() => {
					expect(
						screen.getByText("Found 2 duplicate matches requiring review")
					).toBeInTheDocument();
				},
				{ timeout: 3000 }
			);

			// Check that table headers are present
			expect(screen.getByText("Score")).toBeInTheDocument();
			expect(screen.getByText("Customer A")).toBeInTheDocument();
			expect(screen.getByText("Customer B")).toBeInTheDocument();
			expect(screen.getByText("Actions")).toBeInTheDocument();
		});
	});

	describe("branding", () => {
		it("should display ShopNow branding consistently", () => {
			renderApp();

			const title = screen.getByText("ShopNow - Duplicate Customer Management");
			expect(title).toBeInTheDocument();
			expect(title.tagName).toBe("H1");
		});

		it("should use appropriate font styling", () => {
			renderApp();

			const container = screen
				.getByText("ShopNow - Duplicate Customer Management")
				.closest("div");
			expect(container).toHaveStyle({
				fontFamily:
					"-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
			});
		});
	});

	describe("responsive design", () => {
		it("should have responsive container", () => {
			renderApp();

			const container = screen
				.getByText("ShopNow - Duplicate Customer Management")
				.closest("div");
			expect(container).toHaveStyle({
				maxWidth: "1400px",
				margin: "0 auto",
				padding: "20px",
			});
		});
	});

	describe("accessibility", () => {
		it("should have proper heading hierarchy", () => {
			renderApp();

			const h1 = screen.getByRole("heading", { level: 1 });
			expect(h1).toHaveTextContent("ShopNow - Duplicate Customer Management");
		});

		it("should have descriptive text for users", () => {
			renderApp();

			expect(
				screen.getByText(
					"Review and resolve potential duplicate customer records"
				)
			).toBeInTheDocument();
		});

		it("should indicate connection status clearly", () => {
			renderApp();

			const statusIndicator = screen.getByText("Connected to Salesforce");
			expect(statusIndicator).toBeInTheDocument();

			// Should have visual indicator
			expect(screen.getByText("✅")).toBeInTheDocument();
		});
	});

	describe("integration", () => {
		it("should integrate with React Query properly", async () => {
			renderApp();

			// Should show loading state initially
			expect(
				screen.getByText("Loading duplicate matches...")
			).toBeInTheDocument();

			// Should eventually load data
			await waitFor(
				() => {
					expect(
						screen.getByText("Pending Duplicate Reviews")
					).toBeInTheDocument();
				},
				{ timeout: 3000 }
			);
		});

		it("should handle the complete user workflow", async () => {
			renderApp();

			// 1. App loads
			expect(
				screen.getByText("ShopNow - Duplicate Customer Management")
			).toBeInTheDocument();

			// 2. Data loads
			await waitFor(
				() => {
					expect(
						screen.getByText("Found 2 duplicate matches requiring review")
					).toBeInTheDocument();
				},
				{ timeout: 3000 }
			);

			// 3. Action buttons are available
			expect(screen.getAllByText("Merge")).toHaveLength(2);
			expect(screen.getAllByText("Ignore")).toHaveLength(2);
		});
	});
});
