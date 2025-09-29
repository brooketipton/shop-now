import "@testing-library/jest-dom";
import { beforeAll, afterEach, afterAll } from "vitest";
import { cleanup } from "@testing-library/react";
import { server } from "./mocks/server";

// Start server before all tests
beforeAll(() => server.listen({ onUnhandledRequest: "error" }));

// Clean up after each test case (e.g. clearing jsdom)
afterEach(() => {
	cleanup();
	server.resetHandlers();
});

// Close server after all tests
afterAll(() => server.close());

// Mock localStorage
Object.defineProperty(window, "localStorage", {
	value: {
		getItem: vi.fn(),
		setItem: vi.fn(),
		removeItem: vi.fn(),
		clear: vi.fn(),
	},
	writable: true,
});

// Mock window.location.reload
Object.defineProperty(window, "location", {
	value: {
		reload: vi.fn(),
	},
	writable: true,
});
