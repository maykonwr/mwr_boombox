import { Input, Modal } from "@mantine/core";
import { useEffect, useState } from "react";
import { fetchNui } from "../../../../../utils/fetchNui";

interface Props {
    opened: boolean;
    close(): void;
    newPlaylist(name:string): void;
}

export default function ModalAddPlaylist({opened, close, newPlaylist}:Props) {
    const [name, setName] = useState('');
    const [newPlaylistLabel, setNewPlaylistLabel] = useState('Criar nova playlist');
    const [playlistName, setPlaylistName] = useState('Nome da Playlist');


    const getLibraryLabel = async () => {
        try {
            const res = await fetchNui<string>('newPlaylistLabel');
            if (res) {
                setNewPlaylistLabel(res)
            }
            const res2 = await fetchNui<string>('playlistName');
            if (res2) {
                setPlaylistName(res2)
            }
        } catch (e) {
            console.error(e);
        }
    }

    useEffect(()=>{
        getLibraryLabel();
    }, [])

    return (
        <Modal opened={opened} onClose={close} title={newPlaylistLabel}>
            <Input.Wrapper required maw={320} mx="auto" onChange={(event) => setName((event.target as HTMLInputElement).value)}>
                <Input<any>
                    placeholder={playlistName}
                />
                <div className='contBut'>
                    <button onClick={()=>{close(); newPlaylist(name)}} className='addSongButton'>{newPlaylistLabel}</button>
                </div>
            </Input.Wrapper>
        </Modal>
    );
}