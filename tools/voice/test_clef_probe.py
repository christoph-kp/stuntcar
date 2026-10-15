import base64
import io
import json
from pathlib import Path
import tempfile
import unittest
import wave

try:
    from tools.voice import clef_probe as probe
except ImportError:
    probe = None


class ClefProbeTests(unittest.TestCase):
    def setUp(self):
        self.assertIsNotNone(probe, 'Der Clef-Vergleich fehlt.')

    def test_credentials_are_data_and_never_part_of_prompt(self):
        with tempfile.TemporaryDirectory() as directory:
            env = Path(directory) / '.env'
            env.write_text('CLOUDFLARE="test-secret"\nCLOUDFLARE_ACCOUNT_ID=' + 'a' * 32 + '\n')
            token, account = probe.load_credentials(env)
            self.assertEqual((token, account), ('test-secret', 'a' * 32))
            payload = probe.make_payload(probe.wav_bytes(bytes(3200)), {'distance_m': 80})
            self.assertNotIn(token, json.dumps(payload))
            self.assertNotIn(account, json.dumps(payload))
            self.assertIn('none', payload['questions']['command']['criteria'])

    def test_context_reports_real_curve_direction_and_distance(self):
        track = {'length_m': 940, 'curves': [{'start_m': 90, 'end_m': 170, 'turn_sign': 1, 'radius': 40}],
                 'jumps': [{'start_m': 250, 'end_m': 300}]}
        context = probe.track_context(track, 80, 22)
        self.assertEqual(context['next_curve']['direction'], 'right')
        self.assertEqual(context['next_curve']['distance_to_start_m'], 10)
        self.assertEqual(context['distance_m'], 80)
        self.assertAlmostEqual(context['speed_kmh'], 79.2)
        self.assertEqual(probe.track_context(track, 180, 22)['next_curve'], None)

    def test_wav_has_actual_audio_and_expected_format(self):
        pcm = b'\x01\x02' * 160
        raw = probe.wav_bytes(pcm)
        payload = probe.make_payload(raw, None)
        restored = base64.b64decode(payload['audio'][0].split(',', 1)[1])
        with wave.open(io.BytesIO(restored), 'rb') as stream:
            self.assertEqual((stream.getnchannels(), stream.getsampwidth(), stream.getframerate()), (1, 2, 16000))
            self.assertEqual(stream.readframes(160), pcm)

    def test_results_reject_unknown_choices_and_invalid_confidence(self):
        result = {'answers': {'command': {'choice': 'left', 'confidence': .9,
                  'probabilities': {'left': .9, 'right': .1}}, 'count': {'choice': '1'}}}
        self.assertEqual(probe.parse_result(result)['command'], 'left')
        self.assertEqual(probe.parse_result(result)['count'], 1)
        result['answers']['command']['choice'] = 'turn_anywhere'
        with self.assertRaises(ValueError): probe.parse_result(result)
        result['answers']['command']['choice'] = 'left'
        result['answers']['command']['confidence'] = float('nan')
        with self.assertRaises(ValueError): probe.parse_result(result)


if __name__ == '__main__':
    unittest.main()
