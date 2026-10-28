import {useEffect,useState} from 'react';
import {PageHeader} from '../components/PageHeader';
import {Button,StatusBadge,LoadingState,ErrorState,EmptyState,Notice} from '../components/ui';
import {getReports,updateReport} from '../services/api';
import type {ContentReport} from '../types';

export function Moderation(){
  const [items,setItems]=useState<ContentReport[]|null>(null);
  const [error,setError]=useState('');
  const refresh=()=>getReports().then(setItems).catch(e=>setError(e.message??'Unable to load reports.'));
  useEffect(()=>{refresh()},[]);
  async function act(r:ContentReport, action:ContentReport['status']){
    const message=action==='REVIEWED'
      ? 'Hide this content and resolve all open reports for it?'
      : action==='DISMISSED'
        ? 'Dismiss the report and restore the content if it was auto-hidden?'
        : 'Escalate this report to the safeguarding team?';
    if(!window.confirm(message))return;
    try{await updateReport(r.id,action);await refresh()}catch(e:any){setError(e.message??'Unable to update the report.')}
  }
  if(error&&!items)return <ErrorState message={error}/>;
  if(!items)return <LoadingState/>;
  return <><PageHeader title="Community Moderation" description="Review reports without exposing unnecessary private recovery information."/>
    <Notice type="warning">Safety-sensitive content should be escalated according to your organization's safeguarding policy. The panel does not diagnose users.</Notice>
    <div className="panel"><div className="moderation-banner"><strong>Safety-sensitive queue</strong><span>Categories may include self-harm concerns, substance solicitation, harassment, abuse, unsafe medical claims, dangerous withdrawal advice, fraud and exploitation.</span></div>
      {error&&<div className="inline-error">{error}</div>}
      {!items.length?<EmptyState title="Queue is clear" description="There are no open moderation reports."/>:
      <div className="report-list">{items.map(r=><div className="report-card" key={r.id}><div>
        <div className="report-meta"><StatusBadge status={r.status}/><span>{new Date(r.created_at).toLocaleString()}</span></div>
        <h3>{r.reason}</h3><p>{r.preview??'Content preview is unavailable.'}</p><small>Open reports for target: {r.report_count}</small>
      </div><div className="row-actions">
        <Button variant="secondary" onClick={()=>act(r,'REVIEWED')}>Hide & resolve</Button>
        <Button variant="secondary" onClick={()=>act(r,'DISMISSED')}>Dismiss</Button>
        <Button variant="danger" onClick={()=>act(r,'ESCALATED')}>Escalate</Button>
      </div></div>)}</div>}
    </div></>
}
