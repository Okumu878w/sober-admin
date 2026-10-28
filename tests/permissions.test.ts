import {describe,it,expect} from 'vitest'
const permissions:Record<string,string[]>= {
 SUPER_ADMIN:['events','resources','groups','moderation','support','users','audit'],
 ADMIN:['events','resources','groups','moderation','support','audit'],
 EVENTS_ADMIN:['events','groups'], CONTENT_ADMIN:['resources'], MODERATOR:['moderation'], SUPPORT_ADMIN:['support'], READ_ONLY:['dashboard','events','resources','groups','moderation','support','audit']
}
const can=(role:string,area:string)=>permissions[role]?.includes(area)||permissions[role]?.includes('all')
describe('admin role matrix',()=>{it('super admin can manage everything',()=>expect(can('SUPER_ADMIN','users')).toBe(true));it('events admin cannot manage users',()=>expect(can('EVENTS_ADMIN','users')).toBe(false));it('moderator cannot publish resources',()=>expect(can('MODERATOR','resources')).toBe(false));it('content admin can manage resources',()=>expect(can('CONTENT_ADMIN','resources')).toBe(true));it('read only cannot modify users',()=>expect(can('READ_ONLY','users')).toBe(false))})
