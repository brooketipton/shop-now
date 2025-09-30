import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
	useReactTable,
	getCoreRowModel,
	flexRender,
	createColumnHelper,
} from "@tanstack/react-table";
import { duplicateApi } from "../api-proxy";
import { DuplicateMatch } from "../types";
import styles from "./DuplicateTable.module.css";

const columnHelper = createColumnHelper<DuplicateMatch>();

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
		cell: (info) => <span className={styles.scoreCell}>{info.getValue()}</span>,
	}),
	columnHelper.accessor("customerA", {
		header: "Customer A",
		cell: (info) => {
			const customer = info.getValue();
			return (
				<div className={styles.customerInfo}>
					<div className={styles.customerName}>
						{formatCustomerName(customer.firstName, customer.lastName)}
					</div>
					<div className={styles.customerDetail}>
						{customer.email || "No email"}
					</div>
					<div className={styles.customerDetail}>
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
				<div className={styles.customerInfo}>
					<div className={styles.customerName}>
						{formatCustomerName(customer.firstName, customer.lastName)}
					</div>
					<div className={styles.customerDetail}>
						{customer.email || "No email"}
					</div>
					<div className={styles.customerDetail}>
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
			console.log("Duplicate resolved:", data.message);
			// refresh the duplicates list
			queryClient.invalidateQueries({ queryKey: ["duplicates"] });
		},
		onError: (error) => {
			console.error("Failed to resolve duplicate:", error);
		},
	});

	return (
		<div className={styles.actionButtons}>
			<button
				onClick={() => resolveMutation.mutate({ action: "merge" })}
				disabled={resolveMutation.isPending}
				className={`${styles.actionButton} ${styles.mergeButton}`}>
				{resolveMutation.isPending ? "..." : "Merge"}
			</button>
			<button
				onClick={() => resolveMutation.mutate({ action: "ignore" })}
				disabled={resolveMutation.isPending}
				className={`${styles.actionButton} ${styles.ignoreButton}`}>
				{resolveMutation.isPending ? "..." : "Ignore"}
			</button>
		</div>
	);
}

export default function DuplicateTable() {
	// auto-refresh every 30 seconds to keep data accurate
	const { data, isLoading, error } = useQuery({
		queryKey: ["duplicates"],
		queryFn: () => duplicateApi.getPending(),
		refetchInterval: 30000,
	});

	const table = useReactTable({
		data: data || [],
		columns,
		getCoreRowModel: getCoreRowModel(),
	});

	if (isLoading) {
		return (
			<div className={styles.loadingContainer}>
				Loading duplicate matches...
			</div>
		);
	}

	if (error) {
		return (
			<div className={styles.errorContainer}>
				Error loading duplicates:{" "}
				{error instanceof Error
					? error.message
					: "An unexpected error occurred"}
			</div>
		);
	}

	if (!data || data.length === 0) {
		return (
			<div className={styles.emptyContainer}>
				No pending duplicates found. All matches have been resolved.
			</div>
		);
	}

	return (
		<div>
			<h2>Pending Duplicate Reviews ({data.length})</h2>
			<div className={styles.tableContainer}>
				<table className={styles.table}>
					<thead>
						{table.getHeaderGroups().map((headerGroup) => (
							<tr key={headerGroup.id}>
								{headerGroup.headers.map((header) => (
									<th key={header.id} className={styles.tableHeader}>
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
							<tr key={row.id} className={styles.tableRow}>
								{row.getVisibleCells().map((cell) => (
									<td key={cell.id} className={styles.tableCell}>
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
