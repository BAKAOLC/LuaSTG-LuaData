--======================================
--pause menu
--======================================

----------------------------------------
--暂停菜单

ext.pausemenu={}

ext.pausemenu.mask_color=Color(0,255,255,255)
ext.pausemenu.mask_alph={0,0,0}
ext.pausemenu.mask_x={0,0,0}
ext.pausemenu.text={
	{'Return to Game','Return to Title','Give up and Retry'},
	{'Return to Game','Return to Title','Replay Again'},
}

function ext.pausemenu.New()
	local pm={
		frame=ext.pausemenu.frame,
		render=ext.pausemenu.render,
		kill=false,
	}
	ext.pausemenu.init(pm)
	return pm
end

function ext.pausemenu.init(self)
	self.pos=1
	self.pos2=2
	self.ok=false
	self.choose=false
	self.pos_pre=1
	self.timer=0
	self.t=30
	self.eff=0
	self.pos_changed=0
	self.lock=false
	task.New(self,function()
		local pm=ext.pausemenu
		self.lock=true
		pm.mask_alph={0,0,0}
		pm.mask_x={0,0,0}
		for i=1,50 do
			pm.mask_color=Color(i*4.1,0,0,0)
			pm.mask_alph={
				min(i*8,239),
				max(min((i-10)*8,239),0),
				max(min((i-20)*8,239),0),
			}
			pm.mask_x={
				min(-210+i,-180),
				min(-220+i,-180),
				min(-230+i,-180),
			}
			task.Wait(1)
		end
		self.lock=false
	end)
end

function ext.pausemenu.frame(self)
	--根据是否是replay状态选择暂停菜单文字
	local m
	if ext.replay.IsReplay() then
		m = 2
	else
		m = 1
	end
	--如果有可用的暂停菜单文字，则优先使用已有的
	local pause_menu_text
	if lstg.tmpvar.pause_menu_text then
		pause_menu_text=lstg.tmpvar.pause_menu_text
	else
		pause_menu_text=ext.pausemenu.text[m]
	end
	--检测按键切换槽位
	if GetLastKey()==setting.keys.up and self.t<=0 then
		if not self.choose then
			self.pos=self.pos-1
		else
			self.pos2=self.pos2-1
		end
		PlaySound('select00',0.3)
	end
	if GetLastKey()==setting.keys.down and self.t<=0 then
		if not self.choose then
			self.pos=self.pos+1
		else
			self.pos2=self.pos2+1
		end
		PlaySound('select00',0.3)
	end
	self.pos=(self.pos-1)%(#pause_menu_text)+1
	self.pos2=(self.pos2-1)%(2)+1
	--
	self.timer=self.timer+1
	if self.t>0 then self.t=self.t-1 end
	if self.choose then
		self.eff=min(self.eff+1,15)
	else
		self.eff=max(self.eff-1,0)
	end
	--切换槽位震动
	if self.pos_changed>0 then
		self.pos_changed=self.pos_changed-1
	end
	if self.pos_pre~=self.pos then
		self.pos_changed=ui.menu.shake_time
	end
	self.pos_pre=self.pos
	--执行自身task
	task.Do(self)
	--执行选项操作
	if (GetLastKey()==setting.keysys.menu or GetLastKey()==setting.keys.shoot or GetLastKey()==setting.keys.spell or GetLastKey()==setting.keysys.retry) and not self.lock then
		if GetLastKey()==setting.keysys.retry then
			PlaySound('ok00',0.3)
			lstg.tmpvar.death = false
			self.t=60
			self.pos2=1
			if ext.replay.IsReplay() then
				ext.pause_menu_order='Replay Again'
			else
				ext.pause_menu_order='Give up and Retry'
			end
		end
		if GetLastKey()==setting.keys.shoot and self.t<1 then
			self.t=15
			if not self.choose then
				PlaySound('ok00',0.3)
				if self.pos==1 then
					lstg.tmpvar.death = false
					ext.pause_menu_order=pause_menu_text[self.pos]
				else
					self.choose=true
				end
			else
				if self.pos2==1 then
					PlaySound('ok00',0.3)
					self.t=60
					if not(ext.sc_pr) then
						task.New(self,function()
							local _,bgm=EnumRes('bgm')
							for i=1,30 do
								for _,v in pairs(bgm) do
									if GetMusicState(v)=='playing' then
										SetBGMVolume(v,1-i/30)
									end
								end
								task.Wait(1)
							end
						end)
					end
					self.t=60
					lstg.tmpvar.death = false
					ext.pause_menu_order=pause_menu_text[self.pos]
				else
					self.choose=false
					PlaySound('cancel00',0.3)
					self.t=15
				end
			end
		end
		if GetLastKey()==setting.keys.spell and self.t<1 and self.choose==true then
			self.choose=false
			self.t=15
			PlaySound('cancel00',0.3)
		end
		if not lstg.tmpvar.death and (self.pos2==1 or self.pos==1) then
			task.New(self,function()
				local pm=ext.pausemenu
				self.lock=true
				for i=30,1,-1 do
					pm.mask_color=Color(i*7,0,0,0)
					for j=1,3 do
						pm.mask_alph[j]=i*8
					end
					task.Wait(1)
				end
				task.New(stage.current_stage,function()
					task.Wait(1)
					local _,bgm=EnumRes('bgm')
					for _,v in pairs(bgm) do
						if GetMusicState(v)~='stopped' then
							ResumeMusic(v)
						end
					end
					--[=[
					local sound,_=EnumRes('snd')
					for _,v in pairs(sound) do
						if GetSoundState(v)=='paused' then
							ResumeSound(v)
						end
					end
					]=]
					--StopMusic(deathmusic)
				end)
				
				--不能在这里就直接把自身清除，因为还在执行自身task
				self.kill=true
			end)
		end
	end
end

function ext.pausemenu.render(self)
	--准备一些变量
	local pm=ext.pausemenu
	local dx=208
	local dy=240
	local m
	if ext.replay.IsReplay() then
		m=2
	else
		m=1
	end
	--绘制黑色遮罩
	SetViewMode'ui'
	SetImageState('white','',pm.mask_color)
	RenderRect('white',0,screen.width,0,screen.height)
	--渲染底图
	SetImageState('pause_eff','',Color(pm.mask_alph[1]/3,200*self.eff/15+55,200*(1-self.eff/15)+55,200*(1-self.eff/15)+55))
	Render('pause_eff',-150+180*self.eff/15+dx,-90+dy,4+4*sin(self.timer*3),0.4,0.6)
	--准备选项
	local pause_menu_text
	local pause_menu_choose={'yes','no'}
	if lstg.tmpvar.pause_menu_text then
		pause_menu_text = lstg.tmpvar.pause_menu_text
	else
		pause_menu_text = pm.text[m]
	end
	local textnumber=0
	if pause_menu_text[3] then
		textnumber=3
	else
		textnumber=2
	end
	if pause_menu_text then
		if lstg.tmpvar.pause_menu_text then
			--有现有的文字时高亮处理
			if ext.rep_over then
				if self.choose then
					SetImageState('pause_replyover','',Color(pm.mask_alph[1]+15,100,100,100))
				else
					SetImageState('pause_replyover','',Color(pm.mask_alph[1]+15,255,255,255))
				end
				Render('pause_replyover',pm.mask_x[1]+dx,-30+dy,0,0.7,0.7)
			elseif not ext.sc_pr then
				if self.choose then
					SetImageState('pause_gameover','',Color(pm.mask_alph[1]+15,100,100,100))
				else
					SetImageState('pause_gameover','',Color(pm.mask_alph[1]+15,255,255,255))
				end
				Render('pause_gameover',pm.mask_x[1]+dx,-30+dy,0,0.7,0.7)
			end
		else
			--没有现有的文字时高亮处理
			if m==1 then
				if self.choose then
					SetImageState('pause_pausemenu','',Color(pm.mask_alph[1]+15,100,100,100))
				else
					SetImageState('pause_pausemenu','',Color(pm.mask_alph[1]+15,255,255,255))
				end
				Render('pause_pausemenu',pm.mask_x[1]+dx,-30+dy,0,0.7,0.7)
			else
				if self.choose then
					SetImageState('pause_replyover','',Color(pm.mask_alph[1]+15,100,100,100))
				else
					SetImageState('pause_replyover','',Color(pm.mask_alph[1]+15,255,255,255))
				end
				Render('pause_replyover',pm.mask_x[1]+dx,-30+dy,0,0.7,0.7)
			end
		end
		--渲染选项列表
		for i=1,textnumber do
			if not(self.choose) then
				if i==self.pos and pm.mask_alph[i]+15>=245 then
					SetImageState('pause_'..pause_menu_text[i],'',Color(pm.mask_alph[i]+15,155+100*sin(self.timer*4.5),255,222))
				else
					SetImageState('pause_'..pause_menu_text[i],'',Color(pm.mask_alph[i]+15,100,100,100))
				end
			else
				if i==self.pos and pm.mask_alph[i]+15>=245 then
					SetImageState('pause_'..pause_menu_text[i],'',Color(55,255,255,255))
				else
					SetImageState('pause_'..pause_menu_text[i],'',Color(55,100,100,100))
				end
			end
			Render('pause_'..pause_menu_text[i],pm.mask_x[i]+(1+i)*10+dx,-30-i*40+dy,0,0.62,0.62)
		end
	end
	--渲染确定选项
	if self.choose then
		Render('pause_really',0+dx,-50+dy,0,0.62,0.62)
		for i=1,2 do
			if i==self.pos2 then
				SetImageState('pause_'..pause_menu_choose[i],'',Color(pm.mask_alph[i]+15,155+100*sin(self.timer*4.5),255,255))
			else
				SetImageState('pause_'..pause_menu_choose[i],'',Color(pm.mask_alph[i]+15,100,100,100))
			end
			Render('pause_'..pause_menu_choose[i],15+i*10+dx,-50-i*40+dy,0,0.62,0.62)
		end
	end
	SetViewMode'world'
end

----------------------------------------
--暂停菜单资源

local deathmusic='deathmusic'--疮痍曲

LoadMusic(deathmusic,'THlib\\music\\player_score.ogg',34.834,27.54)
LoadTexture('pause','THlib\\UI\\pause.png')
LoadImage('pause_pausemenu','pause',2,0,168,70)
SetImageCenter('pause_pausemenu',0,35)
LoadImage('pause_gameover','pause',172,0,170,70)
SetImageCenter('pause_gameover',0,35)
LoadImage('pause_replyover','pause',352,0,162,70)
SetImageCenter('pause_replyover',0,35)
LoadImage('pause_Return to Game','pause',0,80,245,60)
SetImageCenter('pause_Return to Game',0,30)
LoadImage('pause_Return to Title','pause',0,140,260,56)
SetImageCenter('pause_Return to Title',0,28)
LoadImage('pause_Give up and Retry','pause',0,197,200,58)
SetImageCenter('pause_Give up and Retry',0,29)
LoadImage('pause_Restart','pause',0,197,200,58)
SetImageCenter('pause_Restart',0,29)
LoadImage('pause_yes','pause',200,196,112,60)
SetImageCenter('pause_yes',0,30)
LoadImage('pause_no','pause',340,196,112,60)
SetImageCenter('pause_no',0,30)
LoadImage('pause_Quit and Save Replay','pause',0,256,360,58)
SetImageCenter('pause_Quit and Save Replay',0,29)
LoadImage('pause_really','pause',0,316,240,60)
SetImageCenter('pause_really',0,30)
LoadImage('pause_savereply','pause',0,368,188,60)
SetImageCenter('pause_savereply',0,30)
LoadImage('pause_Replay Again','pause',0,432,224,56)
SetImageCenter('pause_Replay Again',0,28)
LoadImage('pause_Continue','pause',232,432,120,58)
SetImageCenter('pause_Continue',0,29)
LoadImage('pause_eff','pause',408,320,104,384)
