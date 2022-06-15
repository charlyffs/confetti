export interface User {
    employeeId: number;
    roleId: number;
    username: string;
    passwordHash: string;
    salt: string;
}