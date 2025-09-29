import DuplicateTable from "./components/DuplicateTable";

function App() {
	return (
		<div
			style={{
				padding: "20px",
				maxWidth: "1400px",
				margin: "0 auto",
				fontFamily:
					"-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
			}}>
			<header
				style={{
					marginBottom: "32px",
					paddingBottom: "16px",
					borderBottom: "2px solid #e5e7eb",
				}}>
				<h1
					style={{
						fontSize: "32px",
						fontWeight: "700",
						margin: "0 0 8px 0",
						color: "#111827",
					}}>
					ShopNow - Duplicate Customer Management
				</h1>
				<p
					style={{
						fontSize: "16px",
						color: "#6b7280",
						margin: "0 0 16px 0",
					}}>
					Review and resolve potential duplicate customer records
				</p>
				<div
					style={{
						display: "inline-flex",
						alignItems: "center",
						padding: "8px 12px",
						backgroundColor: "#dcfce7",
						border: "1px solid #bbf7d0",
						borderRadius: "6px",
						fontSize: "14px",
						fontWeight: "500",
						color: "#166534",
					}}>
					<span style={{ marginRight: "6px" }}>✅</span>
					Connected to Salesforce
				</div>
			</header>

			<main>
				<DuplicateTable />
			</main>
		</div>
	);
}

export default App;
