import pathlib
import unittest


class PagesDeploymentConcurrencyTest(unittest.TestCase):
    def test_pr_ci_completions_do_not_cancel_main_deployment(self):
        workflow = pathlib.Path('.github/workflows/deploy-pages.yml').read_text()
        concurrency = workflow.split('concurrency:', 1)[1].split('jobs:', 1)[0]
        self.assertIn('github.event.workflow_run.head_branch', concurrency)
        self.assertIn("github.event_name == 'workflow_dispatch'", concurrency)
        self.assertIn('cancel-in-progress: true', concurrency)
        self.assertNotIn('group: pages\n', concurrency,
                         'Global concurrency lets skipped PR runs cancel main')

    def test_only_green_main_ci_triggers_automatic_deploy(self):
        workflow = pathlib.Path('.github/workflows/deploy-pages.yml').read_text()
        self.assertIn("github.event.workflow_run.conclusion == 'success'", workflow)
        self.assertIn("github.event.workflow_run.head_branch == 'main'", workflow)


if __name__ == '__main__':
    unittest.main()
