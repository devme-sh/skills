// Tiny dev server so the project has a real `bun run dev` to model.
const port = Number(process.env.PORT ?? 3000);
Bun.serve({
  port,
  fetch() {
    return new Response("ok");
  },
});
console.log(`listening on :${port}`);
