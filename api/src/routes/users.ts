import express, {
  Request,
  Response,
  Router,
} from "express";
import pool from "../db";

const router: Router = express.Router();

router.get("/", async (req: Request, res: Response) => {
  try {
    const query = await pool.query("SELECT * FROM employee;");

    res.json(query.rows);
  } catch (error) {
    console.error(error);
  }
});

router.post("/", async (req: Request, res: Response) => {
  try {
    const query = await pool.query(`select checkcredentials('${req.body.username}'::varchar, '${req.body.password}'::varchar);`)
    res.json(query.rows);
  } catch (error) {
    console.error(error);
  }
});

export default router;
