import DuplicateTable from "./components/DuplicateTable";

function App() {
	return (
		<div style={{ padding: "20px", maxWidth: "1200px", margin: "0 auto" }}>
			<h1>Duplicate Management</h1>
			<p style={{ color: "#666", marginBottom: "20px" }}>
				Connected via proxy server - no authentication required
			</p>
			<DuplicateTable />
		</div>
	);
}

export default App;
