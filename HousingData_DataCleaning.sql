USE portfolioproject;

ALTER TABLE `PortfolioProject`.`nashville housing data for data cleaning` 
RENAME TO  `PortfolioProject`.`NashvilleHousing` ;

SELECT * 
  FROM nashvillehousing;

-- Standardise Sale Date

UPDATE NashvilleHousing
SET SaleDate = CONVERT(SaleDate, DATE);

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(SaleDate, DATE);

-- Now we will populate the empty values in the Propoerty Address data

UPDATE NashvilleHousing SET PropertyAddress=IF(PropertyAddress='',NULL,PropertyAddress);

SELECT *
FROM NashvilleHousing
-- WHERE propertyaddress is null
ORDER BY parcelID;


-- Self Join 
-- COALESE converts NULL values from one column to another value specified after it

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, COALESCE(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- USE TEMPORARY TABLE TO UPDATE Property Address 

DROP TEMPORARY TABLE IF EXISTS UpdatePropertyAddress;
CREATE TEMPORARY TABLE UpdatePropertyAddress(
a_ParcelID VARCHAR(50), 
a_PropertyAddress VARCHAR(100), 
b_ParceID VARCHAR(50), 
b_Property_Address VARCHAR(100)
);

INSERT INTO UpdatePropertyAddress
(SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM `PortfolioProject`.`NashvilleHousing` a
JOIN `PortfolioProject`.`NashvilleHousing` b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL);

UPDATE `PortfolioProject`.`NashvilleHousing`
INNER JOIN UpdatePropertyAddress
ON Nashvillehousing.ParcelID = UpdatePropertyAddress.a_ParcelID
SET NashvilleHousing.PropertyAddress = UpdatePropertyAddress.b_Property_Address;

-- Returns no NULL values, shows that PropertyAddress has been updated

SELECT * 
FROM NashvilleHousing
WHERE PropertyAddress IS NULL;


-- Breaking out Address Into Individual Columns (Address, City, State)

SELECT propertyaddress
FROM NashvilleHousing;

-- USE SUBSTRING function to look at property address column at position one. Use LOCATE function to look 
-- for a specific string/char, in a particular column name, returning the char num  ',' is located at, 
-- so adding -1 at the end of the SUBSTRING function would take away the comma

SELECT 
SUBSTRING(PropertyAddress, 1, LOCATE(",", PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, LOCATE(",", PropertyAddress) +1, LENGTH(PropertyAddress)) AS City
FROM NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing 
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(",", PropertyAddress) -1);

ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing 
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(",", PropertyAddress) +1, LENGTH(PropertyAddress));

-- Checking to see the correct values was addded 

SELECT PropertySplitAddress, PropertySplitCity 
FROM NashvilleHousing;

-- USE SUBSTRING_INDEX instead of SUBSTRING to split the Owner Address

SELECT OwnerAddress
FROM NashvilleHousing;

SELECT SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Address,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',2), ',', -1) AS City,
SUBSTRING_INDEX(OwnerAddress, ',', -1) AS State
FROM NashvilleHousing;

ALTER TABLE NashvilleHousing 
ADD COLUMN OwnerSplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE NashvilleHousing 
ADD COLUMN OwnerSplitCity nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',2), ',', -1);

ALTER TABLE NashvilleHousing 
ADD COLUMN OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1);

SELECT OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM NashvilleHousing;
 
 -- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT distinct(Soldasvacant), count(Soldasvacant)
FROM NashvilleHousing
GROUP BY Soldasvacant
ORDER BY Count(soldasvacant);

SELECT Soldasvacant,
	CASE WHEN Soldasvacant = 'Y' THEN 'Yes'
		 WHEN Soldasvacant = 'N' THEN 'No'
         ELSE Soldasvacant
         END
FROM NashvilleHousing;

UPDATE NashvilleHousing
SET Soldasvacant = CASE WHEN Soldasvacant = 'Y' THEN 'Yes'
		 WHEN Soldasvacant = 'N' THEN 'No'
         ELSE Soldasvacant
         END; 
         
-- Removing duplucates in the dataset

With RowNumCTE as(
SELECT *, row_number() OVER (
PARTITION BY ParcelID, 
			 PropertyAddress,
             SalePrice,
             SaleDate,
             LegalReference
             ORDER BY
				UniqueID
                ) row_num
FROM NashvilleHousing
-- ORDER BY ParcelID;
)
SELECT * 
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

-- Returning 104 duplicates 

With RowNumCTE as(
SELECT *, row_number() OVER (
PARTITION BY ParcelID, 
			 PropertyAddress,
             SalePrice,
             SaleDate,
             LegalReference
             ORDER BY
				UniqueID
                ) row_num
FROM NashvilleHousing
-- ORDER BY ParcelID;
)
DELETE  
FROM RowNumCTE
WHERE row_num > 1;
-- ORDER BY PropertyAddress;

-- This delete query (over) did not work, however, I was able to rewrite it into the following query, which deleted the duplicate values:

DELETE FROM NashvilleHousing
WHERE UniqueID NOT IN (
  SELECT UniqueID
  FROM (
    SELECT UniqueID, ROW_NUMBER() OVER (
      PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
      ORDER BY UniqueID
    ) AS row_num
    FROM NashvilleHousing
  ) AS RowNumCTE
  WHERE row_num = 1
);

-- Delete Unused Columns as the Added Column over are more usable

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress;

-- Check final data cleaning results
SELECT * FROM NashvilleHousing;