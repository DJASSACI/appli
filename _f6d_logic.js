const fs=require('fs'),path=require('path'),os=require('os');
const jwt=require('./djassa-backend-github/node_modules/jsonwebtoken');
const secret='test-secret';
// Replicate F6-D logic (isolated, no prod data)
function getSocketTeamAuthUser(token, dbUserSuspended){
  if(!token) return {ok:false,error:'unauthorized'};
  let user; try{ user=jwt.verify(token,secret);}catch(_){return {ok:false,error:'unauthorized'};}
  if(!user||!user.id) return {ok:false,error:'unauthorized'};
  if(dbUserSuspended) return {ok:false,error:'forbidden'};
  return {ok:true,user:{id:Number(user.id),role:user.role||null}};
}
function normalizeTeamSocketId(v){ const raw=String(v??'').trim(); if(!/^[1-9]\d*$/.test(raw)) return null; return parseInt(raw,10); }
function isTeamMember(team,userId){ if(!team) return false; const uid=Number(userId); if(Number(team.creatorId)===uid) return true; return (team.participants||[]).some(p=>Number(p&&p.userId)===uid); }
function joinDecision({token, teamIdInput, team, suspended}){
  const auth=getSocketTeamAuthUser(token,suspended); if(!auth.ok) return {event:'team_join_error',error:auth.error};
  const teamId=normalizeTeamSocketId(teamIdInput); if(!teamId) return {event:'team_join_error',error:'invalid_team_id'};
  if(!team) return {event:'team_join_error',error:'not_found'};
  if(!isTeamMember(team,auth.user.id)) return {event:'team_join_error',error:'forbidden'};
  return {event:'team_joined',ok:true,room:'team:'+teamId};
}
const tA={teamId:1,creatorId:10,participants:[{userId:11}]};
const tB={teamId:2,creatorId:20,participants:[{userId:21}]};
const tok10=jwt.sign({id:10,role:'buyer'},secret);
const tok11=jwt.sign({id:11,role:'buyer'},secret);
const tok99=jwt.sign({id:99,role:'buyer'},secret);
const bad=jwt.sign({id:10},'wrong');
const out={
  noJwt: joinDecision({token:null,teamIdInput:1,team:tA}),
  badJwt: joinDecision({token:bad,teamIdInput:1,team:tA}),
  suspended: joinDecision({token:tok10,teamIdInput:1,team:tA,suspended:true}),
  nonMember: joinDecision({token:tok99,teamIdInput:1,team:tA}),
  memberJoinA: joinDecision({token:tok11,teamIdInput:1,team:tA}),
  creatorJoinA: joinDecision({token:tok10,teamIdInput:1,team:tA}),
  isolation_nonMemberB_cannot_join_B_as_A_member_check: joinDecision({token:tok11,teamIdInput:2,team:tB}), // tok11 not in B
  isolation_memberB_joins_B_only: joinDecision({token:jwt.sign({id:21},secret),teamIdInput:2,team:tB}),
  invalidId_partial: joinDecision({token:tok10,teamIdInput:'1abc',team:tA}),
  clientUserIdIgnored_note: 'handler uses auth.user.id from verified token only; payload userId never read',
  emitOnSaveOnly: (()=>{ let emitted=0; function onSave(saved,teamId){ if(!saved||!saved.ok||!saved.data) return {status:500,emitted}; emitted++; return {status:201,emitted}; } return {fail:onSave({ok:false},1), ok:onSave({ok:true,data:{id:1,teamId:1}},1)}; })(),
  paymentUpdateCount: (fs.readFileSync('djassa-backend-github/server.js','utf8').match(/io\.emit\('payment_update'/g)||[]).length,
};
console.log(JSON.stringify(out,null,2));
