import {supabase,demoMode} from '../lib/supabase'
import {demoAdmin,demoEvents,demoResources,demoGroups,demoReports,demoSupport,demoAudit} from '../lib/demo'
import type {AdminProfile,Event,Resource,SupportGroup,ContentReport,SupportResource,AuditLog} from '../types'

function requireClient(){ if(!supabase) throw new Error('Supabase is not configured. Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY.') ; return supabase }
async function rows<T>(table:string, query=(q:any)=>q):Promise<T[]> { const client=requireClient(); const base=client.from(table).select('*'); const result=await query(base); if(result.error) throw result.error; return (result.data??[]) as T[] }
export async function getAdminProfile(userId:string):Promise<AdminProfile|null>{ if(demoMode) return demoAdmin; const client=requireClient(); const {data,error}=await client.from('admin_profiles').select('*').eq('id',userId).maybeSingle(); if(error) throw error; return data as AdminProfile|null }
export async function signIn(email:string,password:string){ if(demoMode) return {demo:true}; const client=requireClient(); const {error}=await client.auth.signInWithPassword({email,password}); if(error) throw error }
export async function signOut(){ if(demoMode) return; const client=requireClient(); await client.auth.signOut() }
export async function resetPassword(email:string){ const client=requireClient(); const {error}=await client.auth.resetPasswordForEmail(email,{redirectTo:window.location.origin+'/login'}); if(error) throw error }
export async function getSession(){ if(demoMode) return {user:{id:'demo-admin',email:'admin@demo.local'}} as any; return (await requireClient().auth.getSession()).data.session }
export async function getEvents():Promise<Event[]>{ if(demoMode)return demoEvents; return rows<Event>('events',q=>q.order('event_date',{ascending:false})) }
export async function getEvent(id:string){ if(demoMode)return demoEvents.find(x=>x.id===id)??null; const client=requireClient(); const {data,error}=await client.from('events').select('*').eq('id',id).maybeSingle(); if(error)throw error; return data as Event|null }
export async function saveEvent(payload:Partial<Event>,id?:string){ if(demoMode){Object.assign(demoEvents[0],payload);return demoEvents[0]} const client=requireClient(); const result=id?await client.from('events').update(payload).eq('id',id).select().single():await client.from('events').insert(payload).select().single(); if(result.error)throw result.error; return result.data as Event }
export async function updateEventStatus(id:string,status:Event['status'],reason?:string){ return saveEvent({status,cancellation_reason:reason??null,published_at:status==='PUBLISHED'?new Date().toISOString():null},id) }
export async function getResources():Promise<Resource[]>{ if(demoMode)return demoResources; return rows<Resource>('resources',q=>q.order('updated_at',{ascending:false})) }
export async function getResource(id:string){ if(demoMode)return demoResources.find(x=>x.id===id)??null; const client=requireClient(); const {data,error}=await client.from('resources').select('*').eq('id',id).maybeSingle(); if(error)throw error; return data as Resource|null }
export async function saveResource(payload:Partial<Resource>,id?:string){ if(demoMode){Object.assign(demoResources[0],payload);return demoResources[0]} const client=requireClient(); const result=id?await client.from('resources').update(payload).eq('id',id).select().single():await client.from('resources').insert(payload).select().single(); if(result.error)throw result.error; return result.data as Resource }
export async function getGroups():Promise<SupportGroup[]>{
  if(demoMode)return demoGroups;
  return rows<SupportGroup>('v_virtual_groups',q=>q.order('scheduled_time',{ascending:true}))
}
export async function saveGroup(payload:Partial<SupportGroup>,id?:string){
  if(demoMode){
    if(id)Object.assign(demoGroups.find(x=>x.id===id)!,payload);
    else demoGroups.push({...demoGroups[0],...payload,id:crypto.randomUUID()} as SupportGroup);
    return;
  }
  const client=requireClient();
  const groupPayload:any={...payload};
  delete groupPayload.meeting_link;
  delete groupPayload.meeting_id;
  delete groupPayload.meeting_password;
  delete groupPayload.host_name;
  delete groupPayload.updated_at;
  let groupId=id;
  if(id){
    const {error}=await client.from('virtual_support_groups').update(groupPayload).eq('id',id);
    if(error)throw error;
  }else{
    const {data,error}=await client.from('virtual_support_groups').insert(groupPayload).select('id').single();
    if(error)throw error;
    groupId=data.id;
  }
  if(groupId && ('meeting_link' in payload)){
    const {error}=await client.from('group_meeting_details').upsert({
      group_id:groupId,
      meeting_link:payload.meeting_link??null,
      meeting_id:payload.meeting_id??null,
      meeting_password:payload.meeting_password??null
    });
    if(error)throw error;
  }
  return groupId;
}
export async function updateReport(id:string,status:ContentReport['status'],note?:string){
  if(demoMode){
    const r=demoReports.find(x=>x.id===id);
    if(r)Object.assign(r,{status,moderator_note:note??null,reviewed_at:new Date().toISOString()});
    return;
  }
  const client=requireClient();
  if(status==='REVIEWED'){
    const {error}=await client.rpc('resolve_report',{p_report_id:id,p_action:'HIDE'});
    if(error)throw error;
    return;
  }
  if(status==='DISMISSED'){
    const {error}=await client.rpc('resolve_report',{p_report_id:id,p_action:'DISMISS'});
    if(error)throw error;
    return;
  }
  const {error}=await client.from('content_reports').update({
    status:'ESCALATED',
    moderator_note:note??null,
    reviewed_at:new Date().toISOString()
  }).eq('id',id);
  if(error)throw error;
}
export async function getAdmins():Promise<AdminProfile[]>{if(demoMode)return [demoAdmin];return rows<AdminProfile>('admin_profiles',q=>q.order('created_at',{ascending:false}))}
export async function updateAdmin(id:string,payload:Partial<AdminProfile>){if(demoMode){Object.assign(demoAdmin,payload);return}const client=requireClient();const {error}=await client.from('admin_profiles').update(payload).eq('id',id);if(error)throw error}
export async function saveSupport(payload:Partial<SupportResource>,id?:string){if(demoMode){if(id){const r=demoSupport.find(x=>x.id===id);if(r)Object.assign(r,payload)}else demoSupport.push({...payload,id:crypto.randomUUID(),updated_at:new Date().toISOString()} as SupportResource);return}const client=requireClient();const result=id?await client.from('support_resources').update({...payload,updated_at:new Date().toISOString()}).eq('id',id):await client.from('support_resources').insert(payload);if(result.error)throw result.error}
export async function getReports():Promise<ContentReport[]>{
  if(demoMode)return demoReports.filter(r=>r.status==='OPEN');
  const client=requireClient();
  const {data,error}=await client.from('v_open_reports').select('*').order('created_at',{ascending:false});
  if(error)throw error;
  return (data??[]).map((r:any)=>({
    id:r.report_id,
    reason:r.reason,
    status:r.status,
    post_id:r.post_id,
    comment_id:r.comment_id,
    reporter_id:null,
    author_id:r.author_id,
    created_at:r.created_at,
    reviewed_at:r.reviewed_at,
    moderator_note:r.moderator_note,
    report_count:Number(r.open_reports_for_target??1),
    preview:r.post_content??r.comment_content??null
  }));
}
export async function getSupportResources():Promise<SupportResource[]>{if(demoMode)return demoSupport;return rows<SupportResource>('support_resources',q=>q.order('updated_at',{ascending:false}))}
export async function getAuditLogs():Promise<AuditLog[]>{if(demoMode)return demoAudit;return rows<AuditLog>('audit_logs',q=>q.order('created_at',{ascending:false}).limit(100))}
export async function deleteResourceFile(path:string){
  if(demoMode)return;
  const client=requireClient();
  const {error}=await client.storage.from('sober-resources').remove([path]);
  if(error)throw error;
}
export async function uploadResourceFile(file:File,folder='documents'){
  const allowed=['pdf','jpg','jpeg','png','mp3','m4a','mp4'];
  const ext=file.name.split('.').pop()?.toLowerCase()??'';
  const maxBytes=100*1024*1024;
  if(!allowed.includes(ext))throw new Error('Only PDF, JPG, PNG, MP3, M4A and MP4 files are supported.');
  if(file.size>maxBytes)throw new Error('The selected file is larger than the 100 MB upload limit.');
  if(demoMode)return {url:`demo/${folder}/${file.name}`,path:`demo/${folder}/${file.name}`};
  const client=requireClient();
  const safe=file.name.replace(/[^a-zA-Z0-9._-]/g,'_');
  const path=`${folder}/${crypto.randomUUID()}-${safe}`;
  const {error}=await client.storage.from('sober-resources').upload(path,file,{upsert:false,contentType:file.type});
  if(error)throw error;
  const {data}=client.storage.from('sober-resources').getPublicUrl(path);
  return {url:data.publicUrl,path};
}
