import config from './config'
import express, { Application, Request, Response} from "express";

import usersRoutes from "./routes/users";

const app: Application = express();

app.use(express.json());
app.use("/users", usersRoutes);

app.listen(config.NODE_PORT, () => {
  console.log(`Server running on http://localhost:${config.NODE_PORT}`);
});

app.get("/", async (req: Request, res: Response) => {res.send("hello")});
