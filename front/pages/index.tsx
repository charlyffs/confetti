import axios from "axios";
import type { GetServerSideProps, NextPage } from "next";
import Head from "next/head";
import type { User } from "../models/User";
import LoginCard from "../components/loginCard";

type props = {
  users: User[];
};

export const HomeNextPage = (props: props) => {
  return (
    <div>
      <Head>
        <title>Confetti</title>
        <meta name="description" content="Confetti" />
        <meta name="viewport" content="initial-scale=1, width=device-width" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <main>
        <h1 className="text-center text-white font-normal text-6xl">Title</h1>
        <p className="text-white">{JSON.stringify(props.users, null, 4)}</p>
        <p className="text-white">{props.users[0].employeeid}</p>
        <LoginCard />
      </main>

      <footer></footer>
    </div>
  );
};

export const getServerSideProps: GetServerSideProps = async (ctx) => {
  try {
    console.log("api request");
    const {data, status}= await axios.get("http://confetti-api:5000/users");
    const users = data
    console.log('data: ')
    console.log(users);
    return {
      props: {
        users,
      },
    };
  } catch (err) {
    console.log('Error with status code: ' + status);
    return {
      props: {
        users: "",
      },
    };
  }
};

export default HomeNextPage;
