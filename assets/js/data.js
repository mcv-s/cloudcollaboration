import { supabase } from "./supabase.js";
const fail = ({data,error}) => { if(error) throw error; return data; };
export const db = {
  profile: () => supabase.from("profiles").select("*").single().then(fail),
  workspaces: () => supabase.from("workspaces").select("*,workspace_members!inner(role)").order("created_at").then(fail),
  createWorkspace: (input) => supabase.rpc("create_workspace", input).then(fail),
  updateWorkspace: (id,input) => supabase.from("workspaces").update(input).eq("id",id).select().single().then(fail),
  deleteWorkspace: (id) => supabase.from("workspaces").delete().eq("id",id).then(fail),
  members: (workspaceId) => supabase.from("workspace_members").select("workspace_id,user_id,role,joined_at,profiles(display_name,username)").eq("workspace_id",workspaceId).order("joined_at").then(fail),
  updateMember: (workspaceId,userId,role) => supabase.from("workspace_members").update({role}).eq("workspace_id",workspaceId).eq("user_id",userId).select().single().then(fail),
  removeMember: (workspaceId,userId) => supabase.from("workspace_members").delete().eq("workspace_id",workspaceId).eq("user_id",userId).then(fail),
  pages: (workspaceId) => supabase.from("pages").select("*").eq("workspace_id",workspaceId).order("position").order("created_at").then(fail),
  page: (id) => supabase.from("pages").select("*").eq("id",id).single().then(fail),
  createPage: (workspaceId,parentId,title="Untitled") => supabase.rpc("create_page",{p_workspace_id:workspaceId,p_parent_page_id:parentId,p_title:title}).then(fail),
  updatePage: (id,input,expectedUpdatedAt) => supabase.from("pages").update(input).eq("id",id).eq("updated_at",expectedUpdatedAt).select().maybeSingle().then(fail),
  deletePage: (id) => supabase.from("pages").delete().eq("id",id).then(fail),
  invite: (workspaceId,email,role) => supabase.rpc("create_workspace_invitation",{p_workspace_id:workspaceId,p_email:email,p_role:role}).then(fail),
  acceptInvite: (token) => supabase.rpc("accept_workspace_invitation",{p_token:token}).then(fail)
};
