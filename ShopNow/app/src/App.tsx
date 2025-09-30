import DuplicateTable from "./components/DuplicateTable";
import styles from "./App.module.css";

function App() {
	return (
		<div className={styles.container}>
			<header className={styles.header}>
				<h1 className={styles.title}>
					ShopNow - Duplicate Customer Management
				</h1>
				<p className={styles.description}>
					Review and resolve potential duplicate customer records
				</p>
			</header>
			<main>
				<DuplicateTable />
			</main>
		</div>
	);
}

export default App;
