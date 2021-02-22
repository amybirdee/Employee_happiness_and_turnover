--comparing high and low votes by company
SELECT vote_4.company, vote_4.vote_4, vote_3.vote_3, vote_2.vote_2, vote_1.vote_1
FROM
    --seeing how many days an employee voted 4
    (SELECT company, COUNT(vote) AS vote_4
    FROM votes
    WHERE vote = 4
    GROUP BY company
    ORDER BY vote_4 DESC) AS vote_4
FULL JOIN
    --seeing how many days an employee voted 3
    (SELECT company, COUNT(vote) AS vote_3
    FROM votes
    WHERE vote = 3
    GROUP BY company
    ORDER BY vote_3 DESC) AS vote_3
ON vote_4.company = vote_3.company
FULL JOIN
    --seeing how many days an employee voted 2
    (SELECT company, COUNT(vote) AS vote_2
    FROM votes
    WHERE vote = 2
    GROUP BY company
    ORDER BY vote_2 DESC) AS vote_2
ON vote_4.company = vote_2.company
FULL JOIN
    --seeing how many days an employee voted 1
    (SELECT company, COUNT(vote) AS vote_1
    FROM votes
    WHERE vote = 1
    GROUP BY company
    ORDER BY vote_1 DESC) AS vote_1
ON vote_4.company = vote_1.company;

--converting likes and dislikes on comments into a percentage for all employees, current and previous - this query hasn't been used in the final analysis as I didn't think likes and
--dislikes on comments was a very useful metric when details on what the actual comment said was unavailable
SELECT company,
       CASE WHEN total_likes + total_dislikes = 0 THEN 0
       ELSE
       (total_likes * 100) / (total_likes + total_dislikes) END AS total_likes_pc,
       CASE WHEN total_likes + total_dislikes = 0 THEN 0
       ELSE
       (total_dislikes * 100) / (total_likes + total_dislikes) END AS total_dislikes_pc,
       CASE WHEN likes_current + dislikes_current = 0 THEN 0
       ELSE
       (likes_current * 100) / (likes_current + dislikes_current) END AS likes_current_pc,
       CASE WHEN likes_current + dislikes_current = 0 THEN 0
       ELSE
       (dislikes_current * 100) / (likes_current + dislikes_current) END AS dislikes_current_pc,
       CASE WHEN likes_previous + dislikes_previous = 0 THEN 0
       ELSE
       (likes_previous * 100) / (likes_previous + dislikes_previous) END AS likes_previous_pc,
       CASE WHEN likes_previous + dislikes_previous = 0 THEN 0
       ELSE
       (dislikes_previous * 100) / (likes_previous + dislikes_previous) END AS dislikes_previous_pc
FROM
    --comparing likes and dislikes on comments between employees who have stayed and left the company
    (SELECT total.company, total_likes, total_dislikes, total_employees, likes_current, dislikes_current, current_employees, likes_previous, dislikes_previous, previous_employees
    FROM
        --Calculating total likes and dislikes on comments by company
        (SELECT company, SUM(likes) AS total_likes, SUM(dislikes) AS total_dislikes, COUNT(employee_id) AS total_employees
        FROM comments_clean
        GROUP BY company
        ORDER BY total_likes DESC) AS total
    FULL JOIN
        --Calculating total likes and dislikes on comments by company where employee still works there
        (SELECT company, SUM(likes) AS likes_current, SUM(dislikes) AS dislikes_current, COUNT(employee_id) AS current_employees
        FROM comments_clean
        WHERE employee_id > 0
        GROUP BY company
        ORDER BY likes_current DESC) AS current
    ON total.company = current.company
    FULL JOIN
        --Calculating total likes and dislikes on comments by company where employee has left
        (SELECT company, SUM(likes) AS likes_previous, SUM(dislikes) AS dislikes_previous, COUNT(employee_id) AS previous_employees
        FROM comments_clean
        WHERE employee_id < 0
        GROUP BY company
        ORDER BY likes_previous DESC) AS previous
    ON total.company = previous.company) AS sum_values
GROUP BY company, total_likes_pc, total_dislikes_pc, likes_current_pc, dislikes_current_pc, likes_previous_pc, dislikes_previous_pc
ORDER BY total_likes_pc DESC;



--there were lots of duplicates in the churn table so I created a clean version of it in Excel so I could join with the votes table correctly
SELECT company, COUNT(vote) AS total_votes, COUNT(voted_4) AS voted_4, COUNT(voted_3) AS voted_3, COUNT(voted_2) AS voted_2, COUNT(voted_1) AS voted_1, stayed_at_company, left_company
FROM
    (SELECT votes.company, 
          churn_clean.votes, 
          votes.vote, 
          churn_clean.still_exists,
          CASE WHEN vote = 4 THEN 4 END AS voted_4,
          CASE WHEN vote = 3 THEN 3 END AS voted_3,
          CASE WHEN vote = 2 THEN 2 END AS voted_2,
          CASE WHEN vote = 1 THEN 1 END AS voted_1,
          CASE WHEN still_exists = true THEN true END AS stayed_at_company,
          CASE WHEN still_exists = false THEN false END AS left_company
    FROM votes
    JOIN churn_clean
    ON votes.employee_id = churn_clean.employee_id AND votes.company = churn_clean.company
    WHERE votes > 0) AS votes_churn
GROUP BY company, stayed_at_company, left_company;



--votes where employee has stayed as percentage of total (remainer) votes
SELECT company,
       (voted_4 * 100) / (total_votes) AS voted_4_pc,
       (voted_3 * 100) / (total_votes) AS voted_3_pc,
       (voted_2 * 100) / (total_votes) AS voted_2_pc,
       (voted_1 * 100) / (total_votes) AS voted_1_pc,
       stayed_at_company
FROM
    (SELECT company, COUNT(vote) AS total_votes, COUNT(voted_4) AS voted_4, COUNT(voted_3) AS voted_3, COUNT(voted_2) AS voted_2, COUNT(voted_1) AS voted_1, stayed_at_company
    FROM
          (SELECT votes.company, 
          churn_clean.votes, 
          votes.vote, 
          churn_clean.still_exists,
          CASE WHEN vote = 4 THEN 4 END AS voted_4,
          CASE WHEN vote = 3 THEN 3 END AS voted_3,
          CASE WHEN vote = 2 THEN 2 END AS voted_2,
          CASE WHEN vote = 1 THEN 1 END AS voted_1,
          CASE WHEN still_exists = true THEN true END AS stayed_at_company,
          CASE WHEN still_exists = false THEN false END AS left_company
          FROM votes
          JOIN churn_clean
          ON votes.employee_id = churn_clean.employee_id AND votes.company = churn_clean.company
          WHERE votes > 0) AS votes_churn
    WHERE stayed_at_company = true
    GROUP BY company, stayed_at_company
    ORDER BY total_votes DESC) pc_calculation;


--votes where employee has left as percentage of total (leaver) votes
SELECT company,
       (voted_4 * 100) / (total_votes) AS voted_4_pc,
       (voted_3 * 100) / (total_votes) AS voted_3_pc,
       (voted_2 * 100) / (total_votes) AS voted_2_pc,
       (voted_1 * 100) / (total_votes) AS voted_1_pc,
       left_company
FROM
    (SELECT company, COUNT(vote) AS total_votes, COUNT(voted_4) AS voted_4, COUNT(voted_3) AS voted_3, COUNT(voted_2) AS voted_2, COUNT(voted_1) AS voted_1, left_company
    FROM
          (SELECT votes.company, 
          churn_clean.votes, 
          votes.vote, 
          churn_clean.still_exists,
          CASE WHEN vote = 4 THEN 4 END AS voted_4,
          CASE WHEN vote = 3 THEN 3 END AS voted_3,
          CASE WHEN vote = 2 THEN 2 END AS voted_2,
          CASE WHEN vote = 1 THEN 1 END AS voted_1,
          CASE WHEN still_exists = true THEN true END AS stayed_at_company,
          CASE WHEN still_exists = false THEN false END AS left_company
          FROM votes
          JOIN churn_clean
          ON votes.employee_id = churn_clean.employee_id AND votes.company = churn_clean.company
          WHERE votes > 0) AS votes_churn
    WHERE left_company = false
    GROUP BY company, left_company
    ORDER BY total_votes DESC) AS pc_calculation;

--calculating percentage of employees who have stayed and left by company
SELECT company,
       (total_stayed * 100) / (total_stayed + total_left) AS pc_stayed,
       (total_left * 100) / (total_stayed + total_left) AS pc_left
FROM
    (SELECT stayed.company, total_stayed, total_left
    FROM
        --Total who stayed - employee id > 0 because there are lots of employees with negative ids who never voted
        (SELECT company, SUM(votes) AS total_votes, COUNT(still_exists) AS total_stayed
        FROM churn_clean
        WHERE still_exists = true AND employee_id > 0
        GROUP BY company
        ORDER BY SUM(votes) DESC) AS stayed
    FULL JOIN
        --Total who left - employee id > 0 because there are lots of employees with negative ids who never voted
        (SELECT company, SUM(votes) AS total_votes, COUNT(still_exists) AS total_left
        FROM churn_clean
        WHERE still_exists = false AND employee_id > 0
        GROUP BY company
        ORDER BY SUM(votes) DESC) AS left_company
    ON stayed.company = left_company.company) AS pc_calculation;


--comparing high and low votes by company - converting above query to percentages to see if that shows a clearer picture
SELECT company,
       (vote_4 * 100) / (vote_4 + vote_3 + vote_2 + vote_1) AS vote_4_pc,
       (vote_3 * 100) / (vote_4 + vote_3 + vote_2 + vote_1) AS vote_3_pc,
       (vote_2 * 100) / (vote_4 + vote_3 + vote_2 + vote_1) AS vote_2_pc,
       (vote_1 * 100) / (vote_4 + vote_3 + vote_2 + vote_1) AS vote_1_pc
FROM
    (SELECT vote_4.company, vote_4.vote_4, vote_3.vote_3, vote_2.vote_2, vote_1.vote_1
    FROM
        --seeing how many days an employee voted 4
        (SELECT company, COUNT(vote) AS vote_4
        FROM votes
        WHERE vote = 4
        GROUP BY company
        ORDER BY vote_4 DESC) AS vote_4
    FULL JOIN
        --seeing how many days an employee voted 3
        (SELECT company, COUNT(vote) AS vote_3
        FROM votes
        WHERE vote = 3
        GROUP BY company
        ORDER BY vote_3 DESC) AS vote_3
    ON vote_4.company = vote_3.company
    FULL JOIN
        --seeing how many days an employee voted 2
        (SELECT company, COUNT(vote) AS vote_2
        FROM votes
        WHERE vote = 2
        GROUP BY company
        ORDER BY vote_2 DESC) AS vote_2
    ON vote_4.company = vote_2.company
    FULL JOIN
        --seeing how many days an employee voted 1
        (SELECT company, COUNT(vote) AS vote_1
        FROM votes
        WHERE vote = 1
        GROUP BY company
        ORDER BY vote_1 DESC) AS vote_1
    ON vote_4.company = vote_1.company) AS calc_percentage;
    
--votes at companies where 100% of employees stayed
SELECT company, COUNT(vote) AS total_votes, COUNT(voted_4) AS voted_4, COUNT(voted_3) AS voted_3, COUNT(voted_2) AS voted_2, COUNT(voted_1) AS voted_1, stayed_at_company
FROM
          (SELECT votes.company, 
          churn_clean.votes, 
          votes.vote, 
          churn_clean.still_exists,
          CASE WHEN vote = 4 THEN 4 END AS voted_4,
          CASE WHEN vote = 3 THEN 3 END AS voted_3,
          CASE WHEN vote = 2 THEN 2 END AS voted_2,
          CASE WHEN vote = 1 THEN 1 END AS voted_1,
          CASE WHEN still_exists = true THEN true END AS stayed_at_company,
          CASE WHEN still_exists = false THEN false END AS left_company
          FROM votes
          JOIN churn_clean
          ON votes.employee_id = churn_clean.employee_id AND votes.company = churn_clean.company
          WHERE votes > 0) AS votes_churn
WHERE stayed_at_company = true AND company IN ('57d956302a040a00036a8905',
                                               '56e2a905e3b6fe0003e32855',
                                               '5809cc9eff2ea40003fda44d',
                                               '5809cde3ff2ea40003fda452',
                                               '57d979b72a040a00036a8925',
                                               '58b9adfce75bf80004df6536',
                                               '57fcf18712cdbd000396e310',
                                               '58b471b384db3200044dd1b9',
                                               '58c6e15f32f72a00046f556c',
                                               '57e518026d641600035db88a',
                                               '5474b9cde4b0bf7614b2c66f',
                                               '56ae7b02f1ef260003e3072c',
                                               '56558cfd07a5de00030908fb',
                                               '58bf03e5cff4fa0004dd44ef',
                                               '573a0671b5ec330003add34a')
GROUP BY company, stayed_at_company
ORDER BY total_votes DESC;


--votes at companies where employees left
SELECT company, COUNT(vote) AS total_votes, COUNT(voted_4) AS voted_4, COUNT(voted_3) AS voted_3, COUNT(voted_2) AS voted_2, COUNT(voted_1) AS voted_1, left_company
FROM
          (SELECT votes.company, 
          churn_clean.votes, 
          votes.vote, 
          churn_clean.still_exists,
          CASE WHEN vote = 4 THEN 4 END AS voted_4,
          CASE WHEN vote = 3 THEN 3 END AS voted_3,
          CASE WHEN vote = 2 THEN 2 END AS voted_2,
          CASE WHEN vote = 1 THEN 1 END AS voted_1,
          CASE WHEN still_exists = true THEN true END AS stayed_at_company,
          CASE WHEN still_exists = false THEN false END AS left_company
          FROM votes
          JOIN churn_clean
          ON votes.employee_id = churn_clean.employee_id AND votes.company = churn_clean.company
          WHERE votes > 0) AS votes_churn
WHERE left_company = false AND company IN ('573f2c4a3517490003ef7710',
                                           '581b08041a0ef8000308aef6',
                                           '56ab28dc1f385d0003454757',
                                           '57908a2622881200033b34d7',
                                           '53a2dd43e4b01cc02f1e9011',
                                           '5370af43e4b0cff95558c12a',
                                           '57d1eb86a22c9d0003dd1f05',
                                           '567011c035dce00003a07fa4',
                                           '574c423856b6300003009953',
                                           '54d43612e4b0f6a40755d93e',
                                           '57dd2d6a4018d9000339ca43',
                                           '5641f96713664c000332c8cd',
                                           '57bb2f0b3bae540003a8d453',
                                           '56aec740f1ef260003e307d6',
                                           '54e52607e4b01191dc064966',
                                           '57ac8b23be7fe30003e656d0',
                                           '5742d699f839a10003a407d2',
                                           '552e2d00e4b066b42fd122ed',
                                           '56fd2b64f41c670003f643c8',
                                           '58a728a0e75bda00042a3468',
                                           '574c5ade56b6300003009965',
                                           '57c4aa7dbb8b5c000396fd3b')
GROUP BY company, left_company
ORDER BY total_votes DESC;


--case study for Company 8 in analysis - this company had the highest proportion leaving
SELECT company, COUNT(vote) AS total_votes, COUNT(voted_4) AS voted_4, COUNT(voted_3) AS voted_3, COUNT(voted_2) AS voted_2, COUNT(voted_1) AS voted_1, COUNT(DISTINCT(employee_id)) AS number_employees, still_exists
FROM
          (SELECT votes.company, 
          churn_clean.votes, 
          votes.vote, 
          churn_clean.still_exists,
          churn_clean.employee_id,
          CASE WHEN vote = 4 THEN 4 END AS voted_4,
          CASE WHEN vote = 3 THEN 3 END AS voted_3,
          CASE WHEN vote = 2 THEN 2 END AS voted_2,
          CASE WHEN vote = 1 THEN 1 END AS voted_1
          FROM votes
          JOIN churn_clean
          ON votes.employee_id = churn_clean.employee_id AND votes.company = churn_clean.company
          WHERE votes > 0) AS votes_churn
WHERE company LIKE '5370af43e4b0cff95558c12a'
GROUP BY company, still_exists
ORDER BY total_votes DESC;


--case study for Company 7 in analysis - over half of employees who left gave a vote of 1 or 2 at this company
SELECT company, COUNT(vote) AS total_votes, COUNT(voted_4) AS voted_4, COUNT(voted_3) AS voted_3, COUNT(voted_2) AS voted_2, COUNT(voted_1) AS voted_1, COUNT(DISTINCT(employee_id)) AS number_employees, still_exists
FROM
          (SELECT votes.company, 
          churn_clean.votes, 
          votes.vote, 
          churn_clean.still_exists,
          churn_clean.employee_id,
          CASE WHEN vote = 4 THEN 4 END AS voted_4,
          CASE WHEN vote = 3 THEN 3 END AS voted_3,
          CASE WHEN vote = 2 THEN 2 END AS voted_2,
          CASE WHEN vote = 1 THEN 1 END AS voted_1
          FROM votes
          JOIN churn_clean
          ON votes.employee_id = churn_clean.employee_id AND votes.company = churn_clean.company
          WHERE votes > 0) AS votes_churn
WHERE company LIKE '574c5ade56b6300003009965'
GROUP BY company, still_exists
ORDER BY total_votes DESC;


--case study for Company 2 in analysis - more employees who stayed voted 1 compared to 4
SELECT company, COUNT(vote) AS total_votes, COUNT(voted_4) AS voted_4, COUNT(voted_3) AS voted_3, COUNT(voted_2) AS voted_2, COUNT(voted_1) AS voted_1, COUNT(DISTINCT(employee_id)) AS number_employees, still_exists
FROM
          (SELECT votes.company, 
          churn_clean.votes, 
          votes.vote, 
          churn_clean.still_exists,
          churn_clean.employee_id,
          CASE WHEN vote = 4 THEN 4 END AS voted_4,
          CASE WHEN vote = 3 THEN 3 END AS voted_3,
          CASE WHEN vote = 2 THEN 2 END AS voted_2,
          CASE WHEN vote = 1 THEN 1 END AS voted_1
          FROM votes
          JOIN churn_clean
          ON votes.employee_id = churn_clean.employee_id AND votes.company = churn_clean.company
          WHERE votes > 0) AS votes_churn
WHERE company LIKE '54e52607e4b01191dc064966'
GROUP BY company, still_exists
ORDER BY total_votes DESC;
