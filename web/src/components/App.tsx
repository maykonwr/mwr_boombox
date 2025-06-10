import { useEffect, createRef, useState } from "react";
import {debugData} from "../utils/debugData";
import Main from "./Main/Main";
import Repros from "./Repros/Repros";
import { useNuiEvent } from "../hooks/useNuiEvent";
import { fetchNui } from "../utils/fetchNui";
import { Playlist } from "./Main/Library/Library";
import Navbar from "./Navbar/Navbar";

// This will set the NUI to visible if we are
// developing in browser
debugData([
  {
    action: 'setVisible',
    data: true,
  }
])

export interface VideoObject {
    volume: number;
    url: string;
    //@ts-ignore
    playerRef: React.RefObject<YT.Player | null>;
    time: number;
}

interface data {
    repro: number;
    url: string;
    volume: number;
    time: number;
}

interface dataVolume {
    volume: number;
    repro: number;
}

interface dataSong {
    name: string;
    author: string;
    url: string;
    volume: number;
    dist: number;
    maxDuration: number;
    paused: boolean;
    pausedTime: number;
}

const App: React.FC = () => {
    const [reproActive, setReproActive] = useState(-1);
    const [volumeReproActive, setVolumeReproActive] = useState(50);
    const [distReproActive, setDistReproActive] = useState(15);
    const [maxDuration, setMaxDuration] = useState(60);
    const [pausedTime, setPausedTime] = useState(0);
    const [paused, setPaused] = useState(false);
    const [repros, setRepros] = useState<VideoObject[]>([]);
    const [name, setName] = useState('Desconhecido')
    const [timeZone, setTimeZone] = useState('')
    const [author, setAuthor] = useState('Desconhecido')
    const [image, setImage] = useState('https://assets.mriqbox.com.br/scripts/example_cover.png')

    const playSong = (songUrl : string, playlist: Playlist, index: number) => {
        setAuthor(playlist.songs[index].author);
        setImage('https://i.ytimg.com/vi/' + playlist.songs[index].url + '/mqdefault.jpg');
        setName(playlist.songs[index].name);
        const timeMsec = new Date(new Date().toLocaleString('en-US', { timeZone: timeZone })).getTime();
        fetchNui('playSong', {url: songUrl, repro: reproActive, time: timeMsec, playlist: playlist})
    };

    const loadRepro = (repro: number) => {
        setReproActive(repro);
    };

    const createRepro = (data: string) => {
        if (repros.length === 0) {
            setRepros([
                {
                    url: data,
                    playerRef: createRef<YT.Player | null>(),
                    volume: 50,
                    time: 0
                }
            ])
        } else {
            const newRepro: VideoObject = {
                url: data,
                playerRef: createRef<YT.Player | null>(),
                volume: 50,
                time: 0
            };

            setRepros(prevRepros => [...prevRepros, newRepro]);
        }
    };

    const createReproGlobal = (speakers: data[]) => {
        setRepros(speakers.map((speaker : data) => ({
            url: speaker.url,
            playerRef: createRef<YT.Player | null>(),
            volume: speaker.volume,
            time: speaker.time
        })));
        console.log('Speakers loaded in nui')
    };

    const playSongB = (data: data) => {
        const updatedRepros = [...repros];
        if (updatedRepros[data.repro]) {
            updatedRepros[data.repro].url = '';
            setRepros(updatedRepros);
            const uR = [...repros];
            uR[data.repro].url = data.url;
            uR[data.repro].volume = data.volume;
            const timeMsec = new Date(new Date().toLocaleString('en-US', { timeZone: timeZone })).getTime();
            const timeDifferenceInSeconds = Math.floor((timeMsec - data.time) / 1000);
            uR[data.repro].time = timeDifferenceInSeconds;
            setRepros(uR);
            uR[data.repro].playerRef?.current?.seekTo(timeDifferenceInSeconds, false);
        }
    };

    const stopSong = (n: number) => {
        const updatedRepros = [...repros];
        if (updatedRepros[n]) {
            updatedRepros[n].url = '';
            setRepros(updatedRepros);
        }
    }

    const changeVolume = (data:dataVolume) => {
        if (repros[data.repro] && repros[data.repro].playerRef && repros[data.repro].playerRef.current && repros[data.repro]?.playerRef?.current?.getVolume()) {
            repros[data.repro]?.playerRef?.current?.setVolume(data.volume);
        }
    }

    const sendSongInfo = (data:dataSong) => {
        setAuthor(data.author);
        setImage('https://i.ytimg.com/vi/' + data.url + '/mqdefault.jpg');
        setName(data.name);
        setVolumeReproActive(data.volume);
        setDistReproActive(data.dist);
        setMaxDuration(data.maxDuration);
        setPaused(data.paused);
        setPausedTime(data.pausedTime);
    }

    const changeVolumeActive = (n:number) => {
        setVolumeReproActive(n);
        fetchNui('syncVolume', {repro: reproActive, volume: n})
    }

    const tempChangeVolume = (n:number) => {
        if (repros[reproActive]) {
            fetchNui('tempChangeVolume', {repro: reproActive, volume: n})
            setVolumeReproActive(n);
            repros[reproActive]?.playerRef?.current?.setVolume(n);
        }
    }

    const changeDist = (n:number) => {
        setDistReproActive(n);
        fetchNui('changeDist', {repro: reproActive, dist: n})
    }

    const getLibraryLabel = async () => {
        try {
            const res = await fetchNui<string>('Unkown');
            if (res) {
                setName(res)
                setAuthor(res)
            }
        } catch (e) {
            console.error(e);
        }
    }

    const getTimeZone = async () => {
        try {
            const res = await fetchNui<string>('timeZone');
            if (res) {
                setTimeZone(res)
            }
        } catch (e) {
            console.error(e);
        }
    }

    useEffect(()=> {
        fetchNui('webLoaded')
        getLibraryLabel()
        getTimeZone()
    }, [])

    useNuiEvent<number>('setRepro', loadRepro);
    useNuiEvent<string>('createRepro', createRepro);
    useNuiEvent<data[]>('createReproGlobal', createReproGlobal);
    useNuiEvent<data>('playSong', playSongB);
    useNuiEvent<number>('stopSong', stopSong);
    useNuiEvent<dataVolume>('changeVolume', changeVolume);
    useNuiEvent<dataSong>('sendSongInfo', sendSongInfo);

    return (
        <div className="container">
            <Main playSong={playSong}/>
            <Navbar author={author} name={name} image={image} volumeReproActive={volumeReproActive} setVolumeReproActive={changeVolumeActive} tempChangeVolume={tempChangeVolume} distReproActive={distReproActive} setDistReproActive={setDistReproActive} changeDist={changeDist} reproActive={reproActive} maxDuration={maxDuration} repros={repros} paused={paused} pausedTime={pausedTime} />
            <Repros repros={repros} setRepros={setRepros}/>
        </div>
    );
}

export default App;
