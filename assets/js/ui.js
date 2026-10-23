export const $ = (s,root=document) => root.querySelector(s);
export const $$ = (s,root=document) => [...root.querySelectorAll(s)];
export function toast(message,error=false){const el=document.createElement("div");el.className=`toast${error?" error":""}`;el.textContent=message;$("#toast-region").append(el);setTimeout(()=>el.remove(),4500)}
export function show(el){el.classList.remove("hidden")}; export function hide(el){el.classList.add("hidden")};
export function escapeHtml(value=""){return value.replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;","'":"&#39;"}[c]))}
export function formatDate(value){return value?new Intl.DateTimeFormat(undefined,{dateStyle:"medium",timeStyle:"short"}).format(new Date(value)):""}
