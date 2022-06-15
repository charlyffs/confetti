import axios from "axios";
import type { GetServerSideProps, NextPage } from "next";
import Head from "next/head";
import Button from "@mui/material/Button";
import { User } from "../models/User";

const HomeNextPage = ({ users }: IndexProps) => {
  console.log(users)
  return (
    <div>
      <Head>
        <title>Confetti</title>
        <meta name="description" content="Confetti" />
        <meta name="viewport" content="initial-scale=1, width=device-width" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <main>
        <h1 className="text-center text-primary font-normal text-6xl">
          Confetti
        </h1>
        <p>{JSON.stringify(users, null, 4)}</p>
        <Button className="block mx-auto" variant="contained" color="primary">
          Click Me
        </Button>
      </main>

      <footer></footer>
    </div>
  );
};

export interface IndexProps {
  users: User[];
}

export const getServerSideProps: GetServerSideProps = async (
  ctx
) => {
  try {
    console.log("api request");
    const { data, status } = await axios.get(
      'http://confetti-api:5000/users', {
      headers: {
          Accept: "application/json",
        },
      }
    );
    console.log(data, status);
    return {
      props: {
        data,
      },
    };
  } catch (err) {
    console.log(err);
    return {
      props: {
        data: 'err'
      }
    };
  }
};

export default HomeNextPage;
