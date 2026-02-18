import { useEffect, useState,  } from 'react'
import './App.css'

function App({apiEndpoints}) {
  const [dataReady, setDataReady] = useState(false);
  const [data, setData] = useState({});

  useEffect(loadData, []);

  function loadData() {
    fetch(`${apiEndpoints.nowPlayingHost}/playing?mac=1E:9C:DE:1A:EF:CF&width=180&height=180`)
      .then(response => response.json())
      .then(data => {
        setData(data);
        setDataReady(true);
      })
      .catch(error => {
        console.error('Error fetching data:', error);
      });
  }

  const title = data.title;
  const imdbUrl = data ? `https://www.imdb.com/find?q=${title}` : null;
  const letterboxdUrl = data ? `https://letterboxd.com/search/${title}/` : null;

  return (
      dataReady == false
        ? 
          <h2>Loading...</h2>
        : <>
          <div>
            {data.artwork ? <img src={`data:image/jpeg;base64,${data.artwork.bytes}`} alt="Album Artwork" width={data.artwork.width} height={data.artwork.height} /> : null}
          </div>
          <h2>{title == '' ? "[not playing]" : title}</h2>
          <div className="icons">
              {imdbUrl && <a href={imdbUrl} target="_blank" rel="noopener noreferrer"><img src="./imdb.webp" /></a>}
              {letterboxdUrl && <a href={letterboxdUrl} target="_blank" rel="noopener noreferrer"><img src="./letterboxd.webp" /></a>}
          </div>
          <p className="read-the-docs">
          </p>
        </>
  )
}

export default App
