import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
	useReactTable,
	getCoreRowModel,
	flexRender,
	createColumnHelper,
} from "@tanstack/react-table";
import { duplicateApi } from "../api-proxy";
import { DuplicateMatch } from "../types";

const columnHelper = createColumnHelper<DuplicateMatch>();

// Helper function to format customer name
const formatCustomerName = (
	firstName: string | null,
	lastName: string | null
): string => {
	const first = firstName || "";
	const last = lastName || "";
	return `${first} ${last}`.trim() || "Unknown";
};

const columns = [
	columnHelper.accessor("matchScore", {
		header: "Score",
		cell: (info) => `${info.getValue()}`,
	}),
	columnHelper.accessor("customerA", {
		header: "Customer A",
		cell: (info) => {
			const customer = info.getValue();
			return (
				<div>
					<div style={{ fontWeight: "bold" }}>
						{formatCustomerName(customer.firstName, customer.lastName)}
					</div>
					<div style={{ fontSize: "12px", color: "#666" }}>
						{customer.email || "No email"}
					</div>
					<div style={{ fontSize: "12px", color: "#666" }}>
						{customer.phone || "No phone"}
					</div>
				</div>
			);
		},
	}),
	columnHelper.accessor("customerB", {
		header: "Customer B",
		cell: (info) => {
			const customer = info.getValue();
			return (
				<div>
					<div style={{ fontWeight: "bold" }}>
						{formatCustomerName(customer.firstName, customer.lastName)}
					</div>
					<div style={{ fontSize: "12px", color: "#666" }}>
						{customer.email || "No email"}
					</div>
					<div style={{ fontSize: "12px", color: "#666" }}>
						{customer.phone || "No phone"}
					</div>
				</div>
			);
		},
	}),
	columnHelper.display({
		id: "actions",
		header: "Actions",
		cell: (info) => <ActionButtons match={info.row.original} />,
	}),
];

function ActionButtons({ match }: { match: DuplicateMatch }) {
	const queryClient = useQueryClient();

	const resolveMutation = useMutation({
		mutationFn: ({ action }: { action: "merge" | "ignore" }) =>
			duplicateApi.resolve(match.id, action),
		onSuccess: (data) => {
			// Show success message
			console.log("Duplicate resolved:", data.message);
			// Refresh the duplicates list
			queryClient.invalidateQueries({ queryKey: ["duplicates"] });
		},
		onError: (error) => {
			console.error("Failed to resolve duplicate:", error);
		},
	});

	return (
		<div style={{ display: "flex", gap: "8px" }}>
			<button
				onClick={() => resolveMutation.mutate({ action: "merge" })}
				disabled={resolveMutation.isPending}
				style={{
					padding: "8px 16px",
					backgroundColor: resolveMutation.isPending ? "#9ca3af" : "#22c55e",
					color: "white",
					border: "none",
					borderRadius: "4px",
					cursor: resolveMutation.isPending ? "not-allowed" : "pointer",
					fontSize: "14px",
					fontWeight: "500",
				}}>
				{resolveMutation.isPending ? "..." : "Merge"}
			</button>
			<button
				onClick={() => resolveMutation.mutate({ action: "ignore" })}
				disabled={resolveMutation.isPending}
				style={{
					padding: "8px 16px",
					backgroundColor: resolveMutation.isPending ? "#9ca3af" : "#ef4444",
					color: "white",
					border: "none",
					borderRadius: "4px",
					cursor: resolveMutation.isPending ? "not-allowed" : "pointer",
					fontSize: "14px",
					fontWeight: "500",
				}}>
				{resolveMutation.isPending ? "..." : "Ignore"}
			</button>
		</div>
	);
}

export default function DuplicateTable() {
	const { data, isLoading, error } = useQuery({
		queryKey: ["duplicates"],
		queryFn: () => duplicateApi.getPending(),
		refetchInterval: 30000, // Auto-refresh every 30 seconds
	});

	const table = useReactTable({
		data: data || [],
		columns,
		getCoreRowModel: getCoreRowModel(),
	});

	if (isLoading) {
		return (
			<div
				style={{
					display: "flex",
					justifyContent: "center",
					alignItems: "center",
					padding: "40px",
					fontSize: "16px",
				}}>
				Loading duplicate matches...
			</div>
		);
	}

	if (error) {
		return (
			<div
				style={{
					padding: "20px",
					backgroundColor: "#fef2f2",
					border: "1px solid #fecaca",
					borderRadius: "8px",
					color: "#dc2626",
				}}>
				<h3>Error loading duplicates</h3>
				<p>
					{error instanceof Error
						? error.message
						: "An unexpected error occurred"}
				</p>
			</div>
		);
	}

	if (!data || data.length === 0) {
		return (
			<div
				style={{
					padding: "40px",
					textAlign: "center",
					backgroundColor: "#f0fdf4",
					border: "1px solid #bbf7d0",
					borderRadius: "8px",
					color: "#166534",
				}}>
				<h3>No pending duplicates found</h3>
				<p>All duplicate matches have been resolved or no duplicates exist.</p>
			</div>
		);
	}

	return (
		<div>
			<div
				style={{
					marginBottom: "20px",
					padding: "16px",
					backgroundColor: "#eff6ff",
					border: "1px solid #bfdbfe",
					borderRadius: "8px",
				}}>
				<h2 style={{ margin: "0 0 8px 0", color: "#1e40af" }}>
					Pending Duplicate Reviews
				</h2>
				<p style={{ margin: 0, color: "#1e40af" }}>
					Found {data.length} duplicate match{data.length !== 1 ? "es" : ""}{" "}
					requiring review
				</p>
			</div>

			<div
				style={{
					border: "1px solid #e5e7eb",
					borderRadius: "8px",
					overflow: "hidden",
					backgroundColor: "white",
				}}>
				<table style={{ width: "100%", borderCollapse: "collapse" }}>
					<thead>
						{table.getHeaderGroups().map((headerGroup) => (
							<tr key={headerGroup.id}>
								{headerGroup.headers.map((header) => (
									<th
										key={header.id}
										style={{
											padding: "16px",
											textAlign: "left",
											borderBottom: "2px solid #e5e7eb",
											backgroundColor: "#f9fafb",
											fontWeight: "600",
											fontSize: "14px",
											color: "#374151",
										}}>
										{flexRender(
											header.column.columnDef.header,
											header.getContext()
										)}
									</th>
								))}
							</tr>
						))}
					</thead>
					<tbody>
						{table.getRowModel().rows.map((row) => (
							<tr
								key={row.id}
								style={{
									borderBottom: "1px solid #f3f4f6",
								}}>
								{row.getVisibleCells().map((cell) => (
									<td
										key={cell.id}
										style={{
											padding: "16px",
											verticalAlign: "top",
										}}>
										{flexRender(cell.column.columnDef.cell, cell.getContext())}
									</td>
								))}
							</tr>
						))}
					</tbody>
				</table>
			</div>
		</div>
	);
}
