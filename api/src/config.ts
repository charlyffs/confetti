import path from "path";
import dotenv from "dotenv";

// Parsing the env file.
dotenv.config({ path: path.resolve(__dirname, "../.env") });

// Interface to load env variables
// Note these variables can possibly be undefined
// as someone could skip these varibales or not setup a .env file at all

interface ENV {
    NODE_PORT: number | undefined;
    POSTGRES_HOST: string | undefined;
    POSTGRES_NAME: string | undefined;
    POSTGRES_USER: string | undefined;
    POSTGRES_PASSWORD: string | undefined;
    POSTGRES_PORT: number | undefined;
}

interface Config {
    NODE_PORT: number;
    POSTGRES_HOST: string;
    POSTGRES_NAME: string;
    POSTGRES_USER: string;
    POSTGRES_PASSWORD: string;
    POSTGRES_PORT: number;
}

// Loading process.env as ENV interface

const getConfig = (): ENV => {
  return {
    NODE_PORT: process.env.NODE_PORT ? Number(process.env.NODE_PORT) : undefined,
    POSTGRES_USER: process.env.POSTGRES_USER,
    POSTGRES_PASSWORD: process.env.POSTGRES_PASSWORD,
    POSTGRES_NAME: process.env.POSTGRES_NAME,
    POSTGRES_HOST: process.env.POSTGRES_HOST,
    POSTGRES_PORT: process.env.POSTGRES_PORT ? Number(process.env.POSTGRES_PORT) : undefined,
  };
};

// Throwing an Error if any field was undefined we don't 
// want our app to run if it can't connect to DB and ensure 
// that these fields are accessible. If all is good return
// it as Config which just removes the undefined from our type 
// definition.

const getSanitzedConfig = (config: ENV): Config => {
  return config as Config;
};

const config = getConfig();

const sanitizedConfig = getSanitzedConfig(config);

export default sanitizedConfig;