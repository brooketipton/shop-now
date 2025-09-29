export interface CustomerInfo {
	id: string;
	firstName: string;
	lastName: string;
	email: string;
	phone: string;
}

export interface DuplicateMatch {
	id: string;
	customerA: CustomerInfo;
	customerB: CustomerInfo;
	matchScore: number;
	status: string;
}

export interface ApiResponse {
	success: boolean;
	message: string;
}

export interface ApiErrorResponse {
	error: string;
	message: string;
}
