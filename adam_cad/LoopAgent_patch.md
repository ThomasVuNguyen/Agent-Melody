# Patch for LoopAgent: Stop Loop on Successful Evaluation

To ensure your agent loop stops when the evaluation is successful (score >= 90 or comments contain 'all required features satisfied'), update your LoopAgent's run method as follows:

```python
def run(self, instruction):
    reference_description = self.describe_agent.run(instruction)
    feedback = ""
    for i in range(self.max_iters):
        # ... (CAD, Polish, Render steps)
        eval_result = self.evaluate_agent.run(
            instruction=instruction,
            openscad_code=openscad_code,
            image_paths=image_paths
        )
        # If eval_result is a dict:
        score = 0
        comments = ""
        if isinstance(eval_result, dict):
            score = eval_result.get("score", 0)
            comments = eval_result.get("comments", "")
        elif isinstance(eval_result, str):
            # Try to extract score from string if possible
            import re
            match = re.search(r"score.*?(\d+)", eval_result, re.IGNORECASE)
            if match:
                score = int(match.group(1))
            comments = eval_result
        if score >= 90 or "all required features satisfied" in comments.lower():
            print("Design accepted!")
            break
        feedback = comments
```

**Insert this logic after your evaluation agent runs.**
- Adjust the references to your actual variable names if needed.
- This will break out of the loop as soon as a high score or required phrase is detected.

---

If you want, I can directly patch your `agent.py` file with this logic. Let me know if you'd like me to do so automatically!
