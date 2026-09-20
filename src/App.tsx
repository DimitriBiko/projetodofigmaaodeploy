import { useEffect, useState } from 'react'
import AuthScreen from './screens/AuthScreen'
import Home from './screens/Home'
import Search from './screens/Search'
import Messages from './screens/Messages'
import Chat from './screens/Chat'
import Create from './screens/Create'
import Profile from './screens/Profile'
import MyProfile from './screens/MyProfile'
import GroupProfile from './screens/GroupProfile'
import Grupos from './screens/Grupos'
import Settings from './screens/Settings'
import People from './screens/People'
import Members from './screens/Members'
import { useAuth } from './lib/auth'

type Screen =
  | 'login'
  | 'signup'
  | 'home'
  | 'search'
  | 'messages'
  | 'chat'
  | 'create'
  | 'profile'
  | 'myprofile'
  | 'group'
  | 'grupos'
  | 'settings'
  | 'people'
  | 'members'

export default function App() {
  const { session, loading, signOut, isAdmin, profile } = useAuth()
  const [screen, setScreen] = useState<Screen>('login')
  const [chatContactId, setChatContactId] = useState<string>('renata')
  const [profileId, setProfileId] = useState<string>('renata')
  const [groupId, setGroupId] = useState<string>('corrida')
  const [prevScreen, setPrevScreen] = useState<Screen>('home')

  useEffect(() => {
    if (loading) return
    if (session) {
      setScreen((s) => (s === 'login' || s === 'signup' ? 'home' : s))
    } else {
      setScreen((s) => (s === 'login' || s === 'signup' ? s : 'login'))
    }
  }, [session, loading])

  const navigate = (key: string) => {
    if (
      key === 'search' ||
      key === 'messages' ||
      key === 'home' ||
      key === 'create' ||
      key === 'grupos' ||
      key === 'settings' ||
      key === 'people'
    ) {
      setScreen(key as Screen)
    } else if (key === 'profile') {
      setPrevScreen(screen as Screen)
      setScreen('myprofile')
    }
  }

  const openProfile = (personId: string, from: Screen = 'search') => {
    setProfileId(personId)
    setPrevScreen(from)
    setScreen('profile')
  }

  const openGroup = (gId: string, from: Screen = 'home') => {
    setGroupId(gId)
    setPrevScreen(from)
    setScreen('group')
  }

  const homeProps = {
    onNavigate: navigate,
    onOpenGroup: (id: string) => openGroup(id, 'home'),
    onOpenProfile: (id: string) => openProfile(id, 'home'),
    onViewAllPeople: () => {
      setPrevScreen('home')
      setScreen('people')
    },
  }

  if (loading) {
    return (
      <div className="grid h-dvh w-full place-items-center bg-canvas text-neutral-500">
        Carregando…
      </div>
    )
  }

  if (!session) {
    return (
      <AuthScreen
        mode={screen === 'signup' ? 'signup' : 'login'}
        onSwitch={(m) => setScreen(m)}
        onEnter={() => setScreen('home')}
      />
    )
  }

  if (screen === 'search')
    return (
      <>
        <Home {...homeProps} activeKey="search" onOpenGroup={(id) => openGroup(id, 'search')} />
        <Search
          onBack={() => setScreen('home')}
          onOpenProfile={(id) => openProfile(id, 'search')}
          onOpenGroup={(id) => openGroup(id, 'search')}
        />
      </>
    )

  if (screen === 'profile')
    return (
      <>
        <Home {...homeProps} activeKey="home" />
        <Profile
          personId={profileId}
          onBack={() => setScreen(prevScreen)}
          onMessage={(id) => {
            setChatContactId(id)
            setScreen('chat')
          }}
        />
      </>
    )

  if (screen === 'myprofile')
    return (
      <>
        <Home {...homeProps} activeKey="profile" />
        <MyProfile onBack={() => setScreen(prevScreen)} onSettings={() => setScreen('settings')} />
      </>
    )

  if (screen === 'settings')
    return (
      <>
        <Home {...homeProps} activeKey="settings" />
        <Settings
          onBack={() => setScreen('myprofile')}
          onLogout={async () => {
            await signOut()
            setScreen('login')
          }}
          isAdmin={isAdmin}
          adminLabel={profile?.handle}
        />
      </>
    )

  if (screen === 'group')
    return (
      <>
        <Home {...homeProps} activeKey="home" />
        <GroupProfile
          groupId={groupId}
          onBack={() => setScreen(prevScreen)}
          onViewMembers={() => {
            setPrevScreen('group')
            setScreen('members')
          }}
        />
      </>
    )

  if (screen === 'members') {
    const groupNames: Record<string, string> = {
      corrida: 'Corrida para Iniciantes',
      ciclismo: 'Ciclismo Urbano',
      nutricao: 'Nutrição Consciente',
      vida: 'Vida Natural',
      yoga: 'Yoga & Respiração',
      pedal: 'Pedal de Fim de Semana',
    }
    return (
      <>
        <Home {...homeProps} activeKey="home" />
        <Members
          groupName={groupNames[groupId] ?? groupId}
          onBack={() => setScreen('group')}
          onOpenProfile={(id) => openProfile(id, 'members')}
        />
      </>
    )
  }

  if (screen === 'people')
    return (
      <>
        <Home {...homeProps} activeKey="home" />
        <People
          onBack={() => setScreen(prevScreen === 'people' ? 'home' : prevScreen)}
          onOpenProfile={(id) => openProfile(id, 'people')}
        />
      </>
    )

  if (screen === 'grupos')
    return (
      <>
        <Home {...homeProps} activeKey="grupos" onOpenGroup={(id) => openGroup(id, 'grupos')} />
        <Grupos onBack={() => setScreen('home')} onOpenGroup={(id) => openGroup(id, 'grupos')} />
      </>
    )

  if (screen === 'messages')
    return (
      <Messages
        onBack={() => setScreen('home')}
        onSelectContact={(id) => {
          setChatContactId(id)
          setScreen('chat')
        }}
        onOpenProfile={(id) => openProfile(id, 'messages')}
      />
    )

  if (screen === 'chat')
    return <Chat contactId={chatContactId} onBack={() => setScreen('messages')} />

  if (screen === 'create')
    return (
      <>
        <Home {...homeProps} activeKey="create" />
        <Create onClose={() => setScreen('home')} />
      </>
    )

  return <Home {...homeProps} activeKey="home" />
}
