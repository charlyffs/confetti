import React from "react";
import Button from "@mui/material/Button";
import TextField from "@mui/material/TextField";
import Stack from "@mui/material/Stack";
import Image from "next/image"
import logo from "../public/logo.png"

type Props = {};

const login = (props: Props) => {
  return (
    <div className="flex flex-col text-base text-white h-full md:flex-row">
      <span className="flex w-full h-3/5 md:h-full md:w-2/5 self-center items-center">
        <Image
          src={logo}
        />
      </span>
      <div className="w-full h-2/5 md:h-full md:w-3/5 h-full flex items-center bg-slate-500  ">
        <Stack spacing={3} className="p-8 w-3/4 mx-auto">
          <label className="font-bold text-lg">Nombre de usuario</label>
          <TextField
            id="filled-basic"
            label="Escribe algo..."
            variant="outlined"
          />
          <label className="font-bold text-lg">Contraseña</label>
          <TextField
            id="filled-basic"
            label="Escribe algo..."
            variant="outlined"
          />
          <Button className="mx-auto" variant="contained" color="primary">
            Iniciar Sesión
          </Button>
        </Stack>
      </div>
    </div>
  );
};

export default login;
