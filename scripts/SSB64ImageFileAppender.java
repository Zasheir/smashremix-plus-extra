import java.awt.image.*;
import javax.imageio.*;
import java.io.*;
import java.util.Arrays;
import java.nio.file.*;

public class SSB64ImageFileAppender {

    public enum ImageMode {
        RGBA5551,
        IA8,
        I8
    }

    public BufferedImage bi = null;

    public static void main(String[] args) {
        SSB64ImageFileAppender appender = new SSB64ImageFileAppender();
        if (args.length != 2) {
            System.out.println("usage: java -jar SSB64ImageFileAppender.jar <ssb64_file> <image_file_path>");
            System.exit(0);
        }
        appender.run(args[0], args[1]);
    }

    public void run(String ssb64file, String filename) {
        try {
            // init BufferedImage
            this.bi = ImageIO.read(new File(filename));

        } catch (IOException e) {
            // close when file is not present
            System.out.println("File not found!");
            System.exit(0);

        } catch (Exception e) {
            // generic error catch
            System.out.println("Unknown error occured!");
            System.exit(0);
        }

        // create generic data array (ARGB_8888, java default)
        int startX = 0;
        int startY = 0;
        int w = this.bi.getWidth();
        int h = this.bi.getHeight();
        int rgbArray[] = new int[w * h];
        int offset = 0;
        int scansize = w;
        bi.getRGB(startX, startY, w, h, rgbArray, offset, scansize);

        if (ssb64file.equals("0A04")) {
            // Stage Icon
            appendImage(
            "./0A04.bin",
            "0A04-new.bin",
            rgbArray,
            0x28, // width
            0x1E, // height
            ImageMode.RGBA5551,
            null, // colorBytes
            null  // extraBytes
            );
        } else if (ssb64file.equals("0A05")) {
            // Character Icon
            appendImage(
            "./0A05.bin",
            "0A05-new.bin",
            rgbArray,
            0x20,
            0x20,
            ImageMode.RGBA5551,
            null,
            null
            );
        } else if (ssb64file.equals("0011")) {
            // Name Texture
            appendImage(
            "./0011.bin",
            "0011-new.bin",
            rgbArray,
            0x48,
            0x10,
            ImageMode.IA8,
            null,
            null
            );
        } else if (ssb64file.equals("0014")) {
            // Franchise Texture
            appendImage(
            "./0014.bin",
            "0014-new.bin",
            rgbArray,
            0x40,
            0x30,
            ImageMode.I8,
            null,
            null
            );
        } else if (ssb64file.equals("000C")) {
            // Name Texture (Singleplayer)
            appendImage(
            "./000C.bin",
            "000C-new.bin",
            rgbArray,
            w,
            0x0C,
            ImageMode.I8,
            null,
            null
            );
        }
    }

    public byte[] rgba5551(int[] rgbArray) {
        // declare variable for each channel
        int red;
        int green;
        int blue;
        int alpha;
        int argb8888;

        // create RGBA_5551 (16 bits, 2 bytes per pixel)
        byte outArray[] = new byte[rgbArray.length * 2];

        // holds rrrrrggg bits
        byte colorHigh;

        // holds ggbbbbba bits
        byte colorLow;

        // index for outArray
        int j = 0;

        for (int i = 0; i < rgbArray.length; i++) {
            // get color
            argb8888 = rgbArray[i];

            // get channels
            red = (getRed(argb8888) & 0xF8) >> 3;
            green = (getGreen(argb8888) & 0xF8) >> 3;
            blue = (getBlue(argb8888) & 0xF8) >> 3;

            // check for transparency
            alpha = getAlpha(argb8888);
            if (alpha > 0) {
                alpha = 1;
            } else {
                alpha = 0;
            }

            // bit manipulation
            // have
            // 000rrrrr
            // 000ggggg
            // 000bbbbb
            // 0000000a
            // need
            // rrrrrggg
            // ggbbbbba
            colorHigh = 0;
            colorHigh |= red << 3;
            colorHigh |= (green & 0x1D) >> 2;
            colorLow = 0;
            colorLow |= (green & 0x3) << 6;
            colorLow |= blue << 1;
            colorLow |= alpha;

            // update array
            outArray[j + 0] = colorHigh;
            outArray[j + 1] = colorLow;
            j += 2;
        }

        // interleave the array (O(n))
        this.interleave(outArray);

        return outArray;
    }

    public byte[] ia8(int[] rgbArray) {
        // declare variable for each channel
        int intensity;
        int alpha;
        int argb8888;

        // create IA_8 (8 bits, 1 byte per pixel)
        byte outArray[] = new byte[rgbArray.length];

        // index for outArray
        int j = 0;

        for (int i = 0; i < rgbArray.length; i++) {
            // get color
            argb8888 = rgbArray[i];

            // get channels
            intensity = (getRed(argb8888) >> 4) << 4;
            alpha = getAlpha(argb8888) >> 4;
            
            // update array
            outArray[j + 0] = (byte) intensity;
            outArray[j + 0] |= (byte) alpha;
            j += 1;
        }

        // interleave the array (O(n))
        this.interleave(outArray);

        return outArray;
    }

    public byte[] i8(int[] rgbArray) {
        // I8 (8 bits, 1 byte per pixel)
        byte[] outArray = new byte[rgbArray.length];
        for (int i = 0; i < rgbArray.length; i++) {
            int argb = rgbArray[i];
            int intensity = (getRed(argb) + getGreen(argb) + getBlue(argb)) / 3;
            outArray[i] = (byte) (intensity & 0xFF);
        }
        this.interleave(outArray);
        return outArray;
    }

    public void appendImage(
        String inputFile,
        String outputFile,
        int[] imageDataArray,
        int width,
        int height,
        ImageMode mode,
        byte[] colorBytes, // e.g., new byte[]{(byte)0xFF, (byte)0xFF, (byte)0xFF, (byte)0xFF}
        byte[] extraBytes // e.g., any extra bytes that differ between images
    ) {
        byte[] imageData;
        if (mode == ImageMode.IA8) {
            imageData = ia8(imageDataArray);
        } else if (mode == ImageMode.I8) {
            imageData = i8(imageDataArray);
        } else {
            imageData = rgba5551(imageDataArray);
        }

        byte[] currentFile;
        int currentLength = 0;
        byte[] outArray;

        try {
            currentFile = Files.readAllBytes(Paths.get(inputFile));
            currentLength = currentFile.length;

            // next pointer
            if (currentFile[currentLength - 0x14] == -1 && currentFile[currentLength - 0x13] == -1) {
                currentFile[currentLength - 0x14] = (byte) (((currentLength + imageData.length + 0x10) / 4) >> 8);
                currentFile[currentLength - 0x13] = (byte) (((currentLength + imageData.length + 0x10) / 4));
            } else {
                currentFile[currentLength - 0xC] = (byte) (((currentLength + imageData.length + 0x10) / 4) >> 8);
                currentFile[currentLength - 0xB] = (byte) (((currentLength + imageData.length + 0x10) / 4));
            }

            outArray = new byte[imageData.length + currentLength + 0x60];
            System.arraycopy(currentFile, 0, outArray, 0, currentLength);
        } catch (IOException ex) {
            System.out.println("Could not open input file: " + inputFile);
            System.exit(0);
            return;
        }

        int data1, data2, pointer1;
        int j = currentLength;

        // Header
        outArray[j++] = (byte) 0xDF; outArray[j++] = 0x00; outArray[j++] = 0x00; outArray[j++] = 0x00;
        outArray[j++] = 0x00; outArray[j++] = 0x00; outArray[j++] = 0x00; outArray[j++] = 0x00;

        data1 = j / 4;

        // Image data
        System.arraycopy(imageData, 0, outArray, j, imageData.length);
        j += imageData.length;

        data2 = j / 4;
        outArray[j++] = 0x00; outArray[j++] = (byte) width; outArray[j++] = 0x00; outArray[j++] = (byte) width;
        outArray[j++] = 0x00; outArray[j++] = 0x00; outArray[j++] = 0x00; outArray[j++] = 0x00;

        pointer1 = (j + 60) / 4;
        outArray[j++] = (byte) (pointer1 >> 8); outArray[j++] = (byte) pointer1;
        outArray[j++] = (byte) (data1 >> 8); outArray[j++] = (byte) data1;

        outArray[j++] = 0x00; outArray[j++] = (byte) height; outArray[j++] = 0x00; outArray[j++] = 0x00;
        outArray[j++] = 0x00; outArray[j++] = 0x00; outArray[j++] = 0x00; outArray[j++] = 0x00;
        outArray[j++] = 0x00; outArray[j++] = (byte) width; outArray[j++] = 0x00; outArray[j++] = (byte) height;

        // x scale
        outArray[j++] = 0x3F; outArray[j++] = (byte) 0x80; outArray[j++] = 0x00; outArray[j++] = 0x00;
        // y scale
        outArray[j++] = 0x3F; outArray[j++] = (byte) 0x80; outArray[j++] = 0x00; outArray[j++] = 0x00;

        outArray[j++] = 0x00; outArray[j++] = 0x00; outArray[j++] = 0x00; outArray[j++] = 0x00;
        outArray[j++] = 0x02; outArray[j++] = 0x20; outArray[j++] = 0x12; outArray[j++] = 0x34;

        // color (customizable)
        if (colorBytes != null && colorBytes.length == 4) {
            System.arraycopy(colorBytes, 0, outArray, j, 4);
        } else {
            outArray[j] = (byte) 0xFF; outArray[j + 1] = (byte) 0xFF; outArray[j + 2] = (byte) 0xFF; outArray[j + 3] = (byte) 0xFF;
        }
        j += 4;

        outArray[j++] = 0x00; outArray[j++] = 0x00; outArray[j++] = 0x00; outArray[j++] = 0x00;
        outArray[j++] = 0x00; outArray[j++] = 0x00; outArray[j++] = 0x00; outArray[j++] = 0x00;
        outArray[j++] = 0x00; outArray[j++] = 0x00; outArray[j++] = 0x00; outArray[j++] = 0x01;
        outArray[j++] = 0x00; outArray[j++] = 0x01; outArray[j++] = 0x00; outArray[j++] = 0x24;
        outArray[j++] = 0x00; outArray[j++] = (byte) height; outArray[j++] = 0x00; outArray[j++] = (byte) height;

        // Custom bytes for texture type
        if (mode == ImageMode.IA8) { // IA8
            outArray[j++] = 0x03; outArray[j++] = 0x01;
        } else if (mode == ImageMode.I8) { // I8
            outArray[j++] = 0x04; outArray[j++] = 0x01;
        } else { // RGBA5551
            outArray[j++] = 0x00; outArray[j++] = 0x02;
        }
        outArray[j++] = 0x00; outArray[j++] = 0x00;

        outArray[j++] = (byte) 0xFF; outArray[j++] = (byte) 0xFF;
        outArray[j++] = (byte) (data2 >> 8); outArray[j++] = (byte) data2;

        // Extra bytes (customizable)
        if (extraBytes != null) {
            System.arraycopy(extraBytes, 0, outArray, j, extraBytes.length);
            j += extraBytes.length;
        } else {
            // Default: 16 empty lines
            for (int k = 0; k < 16; k++) outArray[j++] = 0x00;
        }

        // output the file
        try (FileOutputStream fos = new FileOutputStream(outputFile)) {
            fos.write(outArray, 0, j);
        } catch (Exception e) {
            System.out.println("Unknown error occurred!");
            System.exit(0);
        }
    }


    public int getAlpha(int argb8888) {
        return (argb8888 >> 24) & 0xFF;
    }

    public int getRed(int argb8888) {
        return (argb8888 >> 16) & 0xFF;
    }

    public int getGreen(int argb8888) {
        return (argb8888 >> 8) & 0xFF;
    }

    public int getBlue(int argb8888) {
        return (argb8888 >> 0) & 0xFF;
    }

    public void interleave(byte[] array) {
        // every other line needs to be interleaved

        // if standard bmp/image data looks like
        // (line 0) AABBCCDD EEFFGGHH
        // (line 1) IIJJKKLL MMNNOOPP
        // (line 2) QQRRSSTT UUVVWWXX
        // (line 3) YYZZ0011 22334455

        // then interleaved data looks like
        // (line 0) AABBCCDD EEFFGGHH
        // (line 1) MMNNOOPP IIJJKKLL
        // (line 2) QQRRSSTT UUVVWWXX
        // (line 3) 22334455 YYZZ0011

        // temp variables to hold swap data
        byte a, b, c, d, e, f, g, h;

        // quick calculation to get number of bytes (image formats have different bytes per pixel)
        int bytesPerLine = array.length / this.bi.getHeight();

        // advance to second line immediately
        int i = bytesPerLine;

        // holds bytes left in a row of image data
        int bytesLeft = bytesPerLine;

        // while i < file length
        while (i < array.length - 7) {

            // if we're at (or near) the end of the line
            if (bytesLeft < 8) {
                // advance to end of the line
                i += bytesLeft;

                // advance to the next line
                i += bytesPerLine;

                // reset bytes left
                bytesLeft = bytesPerLine;
            }

            // save
            a = array[i + 0];
            b = array[i + 1];
            c = array[i + 2];
            d = array[i + 3];
            e = array[i + 4];
            f = array[i + 5];
            g = array[i + 6];
            h = array[i + 7];

            // update
            array[i + 0] = e;
            array[i + 1] = f;
            array[i + 2] = g;
            array[i + 3] = h;
            array[i + 4] = a;
            array[i + 5] = b;
            array[i + 6] = c;
            array[i + 7] = d;

            // inc/dec
            i += 8;
            bytesLeft -= 8;
        }
    }
}
