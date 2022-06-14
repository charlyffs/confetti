import type { NextPage } from "next";
import { NextRouter, Router, useRouter } from "next/router";
import Head from "next/head";
import Button from '@mui/material/Button'



const HomeNextPage: NextPage = () => {
  return (
    <div>
      <Head>
        <title>Confetti</title>
        <meta name="description" content="Confetti" />
        <meta name="viewport" content="initial-scale=1, width=device-width" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <main >
        <h1 className="text-center text-6xl">Confetti</h1>
        <Button variant="contained" color="primary">
          Click Me
        </Button>
      </main>

      <footer></footer>
    </div>
  );
};

export default HomeNextPage;
