export default async (req, context) => {

const data = await req.json()

await fetch(Netlify.env.GOOGLE_SCRIPT_URL,{
method:"POST",
body:JSON.stringify(data)
})

return new Response(JSON.stringify({
status:"ok"
}))

}

export const config = {
path:"/api/ghp"
}
รับข้อมูลจาก LINE
→ ส่งไป Google Sheets