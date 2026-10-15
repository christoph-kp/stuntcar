"""Test source: replay synthetic audio at microphone speed into the real helper."""
import argparse
import json
from pathlib import Path
import sys
import threading
import time
from types import SimpleNamespace
import wave

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from voice.recognizer import Connection, run_microphone

parser = argparse.ArgumentParser()
parser.add_argument('--port', type=int, required=True)
parser.add_argument('--token', required=True)
parser.add_argument('--fixture', required=True)
parser.add_argument('--report', required=True)
args = parser.parse_args()
with wave.open(args.fixture, 'rb') as source:
    assert (source.getframerate(), source.getnchannels(), source.getsampwidth()) == (16000, 1, 2)
    pcm = bytes(16000) + source.readframes(source.getnframes())
# These word ends are estimates from the final transcript, not human annotations.
import vosk
vosk.SetLogLevel(-1)
model = vosk.Model(str(Path(__file__).resolve().parents[2] / '.tools/voice-models/vosk-model-small-de-0.15'))
aligner = vosk.KaldiRecognizer(model, 16000, json.dumps(['links', 'rechts', '[unk]']))
aligner.SetWords(True)
aligner.AcceptWaveform(pcm)
words = json.loads(aligner.FinalResult()).get('result', [])

class InputStream:
    def __init__(self, **kwargs):
        self.callback = kwargs['callback']
        self.done = threading.Event()

    def __enter__(self):
        self.origin = time.monotonic()
        Path(args.report).write_text(json.dumps({'start_unix': time.time(), 'words': words, 'fixture': args.fixture}))
        self.thread = threading.Thread(target=self.play, daemon=True)
        self.thread.start()
        return self

    def play(self):
        offset = 0
        while not self.done.is_set():
            due = self.origin + (offset + 1600) / 32000
            if self.done.wait(max(0, due - time.monotonic())):
                return
            block = pcm[offset:offset + 1600].ljust(1600, b'\0') if offset < len(pcm) else bytes(1600)
            self.callback(block, 800, None, False)
            offset += 1600

    def __exit__(self, *unused):
        self.done.set()
        self.thread.join(timeout=1)

sys.modules['sounddevice'] = SimpleNamespace(RawInputStream=InputStream,
                                            query_devices=lambda *unused: {'name': 'Künstliche Sprachprobe'})
connection = Connection(args.port, args.token)
try:
    run_microphone(connection)
finally:
    connection.socket.close()
