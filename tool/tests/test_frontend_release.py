import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from check_frontend_release import REQUIRED, validate


def manifest(result="PASS"):
    return {
        "schemaVersion": 1,
        "commit": "a" * 40,
        "checks": [
            {"id": check, "result": result, "commit": "a" * 40,
             "artifact": "evidence/trace.json", "detail": "Device and scenario recorded"}
            for check in sorted(REQUIRED)
        ],
    }


class CandidateEvidenceTest(unittest.TestCase):
    def test_complete_evidence(self):
        self.assertEqual(validate(manifest(), True), [])

    def test_ancestor_evidence_cannot_certify_candidate(self):
        document = manifest()
        document["checks"][0]["commit"] = "b" * 40
        with self.assertRaisesRegex(ValueError, "differs from candidate"):
            validate(document)

    def test_pass_without_artifact_is_rejected(self):
        document = manifest()
        document["checks"][0]["artifact"] = " "
        with self.assertRaisesRegex(ValueError, "requires an artifact"):
            validate(document)

    def test_pending_is_valid_work_record_but_not_release(self):
        document = manifest("PENDING")
        self.assertEqual(set(validate(document)), REQUIRED)
        with self.assertRaisesRegex(ValueError, "release incomplete"):
            validate(document, True)

    def test_required_check_cannot_be_skipped(self):
        document = manifest()
        document["checks"][0]["result"] = "N/A"
        with self.assertRaisesRegex(ValueError, "release incomplete"):
            validate(document, True)

    def test_missing_required_check(self):
        document = manifest()
        document["checks"].pop()
        with self.assertRaisesRegex(ValueError, "missing required checks"):
            validate(document)

    def test_duplicate_check(self):
        document = manifest()
        document["checks"].append(document["checks"][0].copy())
        with self.assertRaisesRegex(ValueError, "unique"):
            validate(document)

    def test_unknown_result_or_missing_context(self):
        for field, value in [("result", "SUCCESS"), ("detail", "")]:
            with self.subTest(field=field):
                document = manifest()
                document["checks"][0][field] = value
                with self.assertRaises(ValueError):
                    validate(document)

    def test_malformed_result_is_rejected_without_type_error(self):
        for result in [[], {}, None, 1]:
            with self.subTest(result=result):
                document = manifest()
                document["checks"][0]["result"] = result
                with self.assertRaisesRegex(ValueError, "invalid result"):
                    validate(document)

    def test_schema_version_requires_integer_one(self):
        for version in [True, 1.0, "1", None]:
            with self.subTest(version=version):
                document = manifest()
                document["schemaVersion"] = version
                with self.assertRaisesRegex(ValueError, "unsupported"):
                    validate(document)

    def test_additional_failed_check_blocks_release(self):
        document = manifest()
        document["checks"].append({
            "id": "new-regression", "result": "FAIL", "commit": "a" * 40,
            "artifact": "evidence/failure.log", "detail": "Confirmed regression",
        })
        self.assertEqual(validate(document), ["new-regression"])
        with self.assertRaisesRegex(ValueError, "release incomplete"):
            validate(document, True)


if __name__ == "__main__":
    unittest.main()
