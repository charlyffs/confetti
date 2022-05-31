import {Pool} from 'pg';
import config from './config'

const pool: Pool = new Pool({
    user: config.POSTGRES_USER,
    password: config.POSTGRES_PASSWORD,
    database: config.POSTGRES_NAME,
    host: config.POSTGRES_HOST,
    port: config.POSTGRES_PORT 
});

export default pool;