import React from "react";
import Button from "@mui/material/Button";
import TextField from "@mui/material/TextField";
import Stack from "@mui/material/Stack";

type Props = {};

const loginCard = (props: Props) => {
  return (
    <div className="w-1/2 rounded-3xl bg-slate-200 mx-auto p-8">
      <Stack spacing={3}>
        <label className="block font-bold text-lg">Nombre de usuario</label>
        <TextField
          id="filled-basic"
          label="Escribe algo..."
          variant="outlined"
        />
        <label className="block font-bold text-lg">Contraseña</label>
        <TextField
          id="filled-basic"
          label="Escribe algo..."
          variant="outlined"
        />
        <Button className="block mx-auto" variant="contained" color="primary">
          Iniciar Sesión
        </Button>
      </Stack>
    </div>
  );
};

export default loginCard;
