import {Pool} from 'pg';
import config from './config'

const pool: Pool = new Pool({
    user: config.POSTGRES_USER,
    password: config.POSTGRES_PASSWORD,
    database: config.POSTGRES_NAME,
    host: config.POSTGRES_HOST,
    port: 5432
});

export default pool;